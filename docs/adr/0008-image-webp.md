# ADR 0008: 画像はアップロード時に WebP へ変換・縮小 / 이미지는 업로드 시 WebP 변환·축소

状態 / 상태: 採用 / 채택 (2026-10)

## 決定 / 결정
`image_processing`（libvips）で、アップロード時に WebP へ変換し長辺 1600px 以下・品質 82 に縮小（EXIF の位置情報は削除）。5MB 超の元ファイルは処理せず検証エラー。表示は用途別の variant、`loading="lazy"`（ファーストビューの画像は `eager` + `fetchpriority=high`）。GIF は変換しない。

## 理由 / 이유
転送量・ディスク・ LCP の改善。スマホ写真（数MB）をそのまま載せると遅い。libvips は ImageMagick よりメモリが少ない。
