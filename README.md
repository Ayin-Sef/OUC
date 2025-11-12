# OUC — Our Universe Coherence

**Теория Когерентного Гиперполя Вселенной**  
*GPL-3.0 License* | 2025 | Ayin-Sef

> **Вселенная — не пространство с материей, а гиперполе когерентности**  
> \(\Psi(x,t) = C(x,t) e^{i\phi(x,t)}\)

## Ключевые идеи
- **Частицы** — топологические узлы \(C < 1\)
- **Гравитация** — фазовое рассогласование \(T = \nabla D\), \(D = 1 - C\)
- **Расширение** — диффузия когерентности к \(H(t) \to 1\)
- **Тёмная энергия** — остаточная декогеренция

## Уравнения
\[
\partial_t C = -\alpha(1-C) + \beta \nabla^2 C + 2\gamma F(H,E)
\]
\[
V(C) = A(C-1)^2 + B(C-C^*)^4, \quad m \propto V''(C^*)
\]

## Структура
- `docs/` — полная теория
- `simulations/` — Python-симуляции
- `paper/` — LaTeX-драфт

## Запуск
```bash
git clone https://github.com/Ayin-Sef/OUC.git
cd simulations
python expansion.py
