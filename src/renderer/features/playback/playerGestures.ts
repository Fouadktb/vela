interface DoubleClickSeekInput {
  clientX: number;
  left: number;
  width: number;
  isSeekable: boolean;
}

export function getSeekSecondsForDoubleClick(input: DoubleClickSeekInput): -10 | 0 | 10 {
  if (!input.isSeekable || input.width <= 0) {
    return 0;
  }

  const midpoint = input.left + input.width / 2;
  return input.clientX < midpoint ? -10 : 10;
}
