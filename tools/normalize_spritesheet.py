"""Junta e normaliza spritesheets gerados por IA para importar na Godot.

Cada imagem de entrada é UMA animação (ex.: telegrafia, arremesso...), gerada separada na IA.
O script:
  1. Remove o fundo se a imagem vier sem transparência (cor dos cantos, a partir das bordas).
  2. Separa os quadros pela grade COLSxROWS que a IA desenhou, sem cortar em linha reta
     (cada mancha de pixels vai para o quadro onde está o centro dela).
  3. Deixa o personagem do MESMO tamanho em todas as imagens: cada imagem é escalada pela
     altura mediana dos quadros dela (IA gera cada imagem num tamanho diferente).
     Com --match, essa altura fica igual à do personagem num sheet que já está no jogo.
  4. Cola cada quadro numa célula de tamanho fixo, com os pés no chão da célula e
     centralizado pelas pernas (assim o boss não "pula" de lugar entre os quadros).
     Para objetos (espada), use --align center.
  5. Salva um PNG só: cada entrada vira uma LINHA, na ordem dada. Na Godot,
     "Adicionar quadros de um sprite sheet" com as colunas/linhas que o script imprimir.

Entradas no formato arquivo.png:COLSxROWS (ex.: telegrafia.png:3x1).

Uso:
  python tools/normalize_spritesheet.py --out boss_sword_throw.png --match assets/sprites/enemies/boss_uppercut.png:4x2       telegrafia.png:3x1 arremesso.png:2x1 espera.png:1x1 recuperacao.png:2x1
  python tools/normalize_spritesheet.py --out thrown_sword.png --cell 192x64 --align center espada.png:4x1
"""
import argparse
from collections import deque

import numpy as np
from PIL import Image, ImageFilter

ALPHA_MIN = 16  # pixels mais transparentes que isso são ignorados (ruído)


def remove_background(img: Image.Image, tolerance: int) -> Image.Image:
	"""Apaga o fundo ligado às bordas que tem a cor média dos cantos."""
	rgba = np.array(img.convert("RGBA"))
	if rgba[..., 3].min() < 255:
		return img.convert("RGBA")  # já tem transparência

	h, w = rgba.shape[:2]
	rgb = rgba[..., :3].astype(int)
	corners = np.array([rgb[0, 0], rgb[0, -1], rgb[-1, 0], rgb[-1, -1]])
	bg = corners.mean(axis=0)
	similar = np.abs(rgb - bg).max(axis=2) <= tolerance

	# flood fill a partir das bordas: só apaga fundo encostado na borda,
	# não o branco de dentro do personagem
	visited = np.zeros((h, w), bool)
	queue = deque()
	for x in range(w):
		queue.extend([(0, x), (h - 1, x)])
	for y in range(h):
		queue.extend([(y, 0), (y, w - 1)])
	while queue:
		y, x = queue.popleft()
		if visited[y, x] or not similar[y, x]:
			continue
		visited[y, x] = True
		if y > 0: queue.append((y - 1, x))
		if y < h - 1: queue.append((y + 1, x))
		if x > 0: queue.append((y, x - 1))
		if x < w - 1: queue.append((y, x + 1))

	rgba[visited, 3] = 0
	return Image.fromarray(rgba)


def bbox(frame: Image.Image):
	alpha = np.array(frame)[..., 3]
	ys, xs = np.nonzero(alpha >= ALPHA_MIN)
	if len(xs) == 0:
		return None
	return xs.min(), ys.min(), xs.max() + 1, ys.max() + 1


def label_blobs(mask: np.ndarray):
	"""Rotula as manchas conectadas (vizinhança 8) de uma máscara booleana."""
	h, w = mask.shape
	labels = np.zeros((h, w), np.int32)
	count = 0
	for sy, sx in zip(*np.nonzero(mask)):
		if labels[sy, sx]:
			continue
		count += 1
		labels[sy, sx] = count
		queue = deque([(sy, sx)])
		while queue:
			y, x = queue.popleft()
			for ny in (y - 1, y, y + 1):
				for nx in (x - 1, x, x + 1):
					if 0 <= ny < h and 0 <= nx < w and mask[ny, nx] and not labels[ny, nx]:
						labels[ny, nx] = count
						queue.append((ny, nx))
	return labels, count


def split_frames(img: Image.Image, cols: int, rows: int, merge: int) -> list:
	"""Separa os quadros sem cortar em linha reta: a IA não respeita a grade e um desenho
	costuma invadir a célula vizinha. Partículas a até ~merge px do corpo contam como dele."""
	step = 2  # rotula numa versão reduzida (bem mais rápido)
	alpha = np.array(img)[..., 3] >= ALPHA_MIN
	small = Image.fromarray(alpha.astype(np.uint8) * 255).reduce(step)
	small = np.array(small) > 0
	size = (merge // step) * 2 + 1
	if size > 1:
		small = np.array(Image.fromarray(small.astype(np.uint8) * 255).filter(ImageFilter.MaxFilter(size))) > 0
	labels, count = label_blobs(small)

	# célula da grade de cada pixel (corte reto)
	gw, gh = small.shape[1] / cols, small.shape[0] / rows
	grid_c = np.minimum(cols - 1, (np.arange(small.shape[1]) / gw).astype(int))
	grid_r = np.minimum(rows - 1, (np.arange(small.shape[0]) / gh).astype(int))
	grid_cell = grid_r[:, None] * cols + grid_c[None, :]

	# mancha que cabe numa célula vai inteira para a célula do centro dela; mancha maior
	# (dois desenhos encostados) é cortada na linha da grade
	cell_map = np.full(small.shape, -1, np.int32)
	touching = 0
	for lab in range(1, count + 1):
		blob = labels == lab
		ys, xs = np.nonzero(blob)
		if xs.max() - xs.min() > 1.2 * gw or ys.max() - ys.min() > 1.2 * gh:
			cell_map[blob] = grid_cell[blob]
			touching += 1
			continue
		c = min(cols - 1, int(xs.mean() / gw))
		r = min(rows - 1, int(ys.mean() / gh))
		cell_map[blob] = r * cols + c
	if touching:
		print(f"aviso: {touching} grupo(s) de quadros encostados, cortados na linha da grade; confira o resultado")

	# volta para o tamanho original e monta um quadro por célula
	cell_map = np.array(Image.fromarray(cell_map.astype(np.int16) + 1).resize(img.size, Image.NEAREST)).astype(int) - 1
	rgba = np.array(img)
	frames = []
	for i in range(cols * rows):
		part = rgba.copy()
		part[(cell_map != i), 3] = 0
		frames.append(Image.fromarray(part))
	return frames


def legs_center_x(frame: Image.Image) -> float:
	"""Centro horizontal dos pixels no quarto de baixo do desenho (as pernas)."""
	alpha = np.array(frame)[..., 3]
	h = alpha.shape[0]
	bottom = alpha[int(h * 0.75):] >= ALPHA_MIN
	xs = np.nonzero(bottom.any(axis=0))[0]
	if len(xs) == 0:
		return frame.width / 2
	return (xs.min() + xs.max()) / 2


def parse_input(text: str):
	"""arquivo.png:COLSxROWS -> (arquivo, cols, rows)"""
	path, _, grid = text.rpartition(":")
	if not path or "x" not in grid.lower():
		raise SystemExit(f"entrada '{text}' inválida; use arquivo.png:COLSxROWS (ex.: telegrafia.png:3x1)")
	cols, rows = (int(v) for v in grid.lower().split("x"))
	return path, cols, rows


def load_frames(text: str, tolerance: int, merge: int) -> list:
	"""Abre uma entrada e devolve os quadros recortados no tamanho do desenho."""
	path, cols, rows = parse_input(text)
	img = remove_background(Image.open(path), tolerance)
	frames = []
	for i, frame in enumerate(split_frames(img, cols, rows, merge)):
		box = bbox(frame)
		if box is None:
			print(f"aviso: {path}: quadro {i} vazio, ignorado")
			continue
		frames.append(frame.crop(box))
	if not frames:
		raise SystemExit(f"{path}: nenhum quadro encontrado")
	return frames


def median_height(frames: list) -> float:
	return float(np.median([f.height for f in frames]))


def main() -> None:
	parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
	parser.add_argument("inputs", nargs="+", help="arquivo.png:COLSxROWS, uma entrada por animação")
	parser.add_argument("--out", required=True, help="PNG de saída")
	parser.add_argument("--cell", default="144x216",
		help="tamanho de cada célula na saída (padrão do boss_uppercut). Pode ser mais largo se o golpe "
			"tiver o braço esticado, mas mantenha a altura igual à dos outros sheets do boss")
	parser.add_argument("--match", default="",
		help="arquivo.png:COLSxROWS de um sheet que já está no jogo: o personagem fica com a mesma altura dele")
	parser.add_argument("--height", type=int, default=0,
		help="altura típica (mediana) do personagem em px na saída; ignora --match")
	parser.add_argument("--align", choices=["feet", "center"], default="feet",
		help="feet: pés no chão da célula (personagem); center: no meio da célula (objetos)")
	parser.add_argument("--margin", type=int, default=4, help="folga em px nas bordas da célula")
	parser.add_argument("--floor", type=int, default=-1,
		help="distância em px dos pés até a base da célula (padrão = --margin). Use o mesmo valor dos "
			"outros sheets para os pés ficarem na mesma altura no jogo")
	parser.add_argument("--flip", action="store_true",
		help="espelha na horizontal (a IA desenhou o personagem olhando para o lado contrário dos outros sheets)")
	parser.add_argument("--merge", type=int, default=2,
		help="partículas a até N px do corpo contam como do mesmo quadro (aumente se faíscas sumirem, diminua se quadros se juntarem)")
	parser.add_argument("--tolerance", type=int, default=30, help="tolerância de cor para apagar o fundo")
	args = parser.parse_args()

	cell_w, cell_h = (int(v) for v in args.cell.lower().split("x"))
	room_w = cell_w - 2 * args.margin
	room_h = cell_h - args.margin - (args.margin if args.floor < 0 else args.floor)
	animations = [load_frames(text, args.tolerance, args.merge) for text in args.inputs]
	if args.flip:
		animations = [[f.transpose(Image.FLIP_LEFT_RIGHT) for f in frames] for frames in animations]
	floor = args.margin if args.floor < 0 else args.floor

	# 1) altura alvo do personagem (mediana dos quadros)
	target = float(args.height)
	if target <= 0 and args.match:
		target = median_height(load_frames(args.match, args.tolerance, args.merge))
		print(f"altura do personagem em {parse_input(args.match)[0]}: {target:.0f} px")

	# 2) escala de cada animação: mesma altura mediana em todas. Se algum quadro não couber na
	# célula, TODAS encolhem juntas (para o tamanho continuar igual entre as animações)
	scales = [1.0 / median_height(frames) for frames in animations]
	biggest = min(min(room_w / (f.width * s), room_h / (f.height * s)) for frames, s in zip(animations, scales) for f in frames)
	k = biggest if target <= 0 else min(target, biggest)
	if target > 0 and k < target:
		print(f"aviso: altura {target:.0f} px não cabe na célula {cell_w}x{cell_h}; usando {k:.0f} px "
			"(aumente --cell se o personagem tiver ficado menor que nos outros sheets)")
	scales = [s * k for s in scales]

	# 3) monta a saída: uma linha por animação
	out_cols = max(len(frames) for frames in animations)
	sheet = Image.new("RGBA", (out_cols * cell_w, len(animations) * cell_h), (0, 0, 0, 0))
	for row, (frames, scale) in enumerate(zip(animations, scales)):
		for col, frame in enumerate(frames):
			frame = frame.resize((max(1, round(frame.width * scale)), max(1, round(frame.height * scale))), Image.LANCZOS)
			if args.align == "feet":
				x = round(cell_w / 2 - legs_center_x(frame))
				y = cell_h - floor - frame.height
			else:
				x = round((cell_w - frame.width) / 2)
				y = round((cell_h - frame.height) / 2)
			x = max(0, min(x, cell_w - frame.width))  # não deixa sair da célula
			sheet.alpha_composite(frame, (col * cell_w + x, row * cell_h + y))

	sheet.save(args.out)
	print(f"-> {args.out}: célula {cell_w}x{cell_h}, grade {out_cols} colunas x {len(animations)} linhas")
	for row, (text, frames) in enumerate(zip(args.inputs, animations)):
		print(f"   linha {row + 1}: {parse_input(text)[0]} ({len(frames)} quadros)")


if __name__ == "__main__":
	main()
