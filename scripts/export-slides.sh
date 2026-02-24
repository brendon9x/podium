#!/bin/bash
# scripts/export-slides.sh
# Exports demo .pptx slides to PNG images for guide documentation.
# Requires: macOS with Microsoft PowerPoint installed.
#
# Strategy: PowerPoint's AppleScript "save as PNG" is broken (known issue).
# Instead we export each .pptx to PDF (which works), then use macOS's built-in
# CoreGraphics Python bindings to render each PDF page as a PNG.
#
# Usage: ./scripts/export-slides.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
INPUT_DIR="$PROJECT_DIR/demos/output"
ASSETS_DIR="$PROJECT_DIR/guides/assets"
TEMP_DIR="$PROJECT_DIR/.slide-export-tmp"

# Mapping: "pptx_basename|slide_number|section/guide-name|filename"
# Sorted by pptx name so we can batch exports per file.
SLIDES=(
  "building-a-report|1|recipes/building-a-report|title-slide"
  "building-a-report|2|recipes/building-a-report|executive-summary"
  "building-a-report|3|recipes/building-a-report|revenue-chart"
  "building-a-report|4|recipes/building-a-report|market-share-pie"
  "building-a-report|5|recipes/building-a-report|department-table"
  "building-a-report|6|recipes/building-a-report|trend-line-chart"
  "building-a-report|7|recipes/building-a-report|conclusion"

  "charts|1|core/charts|column-clustered"
  "charts|2|core/charts|bar-stacked"
  "charts|3|core/charts|line-markers"
  "charts|4|core/charts|pie-chart"
  "charts|5|core/charts|radar-filled"
  "charts|6|core/charts|scatter-chart"
  "charts|7|core/charts|bubble-chart"
  "charts|8|core/charts|pattern-fills-per-point"

  "combo-charts|1|advanced/combo-charts|column-line-overlay"
  "combo-charts|2|advanced/combo-charts|stacked-column-line"
  "combo-charts|3|advanced/combo-charts|area-line-secondary-axis"

  "connectors-and-freeforms|1|advanced/connectors-and-freeforms|flowchart-connectors"
  "connectors-and-freeforms|2|advanced/connectors-and-freeforms|freeform-triangle-star"
  "connectors-and-freeforms|3|advanced/connectors-and-freeforms|multi-contour-cutout"

  "html-text|1|web-layer/html-text|basic-formatting"
  "html-text|2|web-layer/html-text|lists"
  "html-text|5|web-layer/html-text|html-in-tables"

  "getting-started|1|introduction/getting-started|title-slide"
  "getting-started|2|introduction/getting-started|rich-text-bullets"
  "getting-started|3|introduction/getting-started|column-chart"
  "getting-started|4|introduction/getting-started|formatted-table"
  "getting-started|5|introduction/getting-started|title-content-layout"

  "hyperlinks-and-actions|1|advanced/hyperlinks-and-actions|url-email-links"
  "hyperlinks-and-actions|2|advanced/hyperlinks-and-actions|navigation-buttons"
  "hyperlinks-and-actions|3|advanced/hyperlinks-and-actions|table-of-contents"

  "images|1|core/images|basic-placement"
  "images|2|core/images|shape-mask-cropping"
  "images|3|core/images|image-rotation"

  "placeholders|1|core/placeholders|title-slide-layout"
  "placeholders|2|core/placeholders|comparison-layout"
  "placeholders|3|core/placeholders|content-caption-layout"
  "placeholders|4|core/placeholders|two-content-layout"
  "placeholders|5|core/placeholders|chart-placeholder"

  "percent-layout|2|web-layer/percent-positioning|four-quadrants"
  "percent-layout|4|web-layer/percent-positioning|mixed-units"

  "presentations-and-slides|1|core/presentations-and-slides|title-slide-footer"
  "presentations-and-slides|2|core/presentations-and-slides|solid-background"
  "presentations-and-slides|3|core/presentations-and-slides|gradient-background"
  "presentations-and-slides|4|core/presentations-and-slides|pattern-background"

  "shapes-and-styling|1|core/shapes-and-styling|shape-gallery"
  "shapes-and-styling|2|core/shapes-and-styling|fill-types"
  "shapes-and-styling|3|core/shapes-and-styling|line-styles"
  "shapes-and-styling|4|core/shapes-and-styling|text-in-shapes-rotation"

  "slide-backgrounds-and-notes|1|advanced/slide-backgrounds-and-notes|solid-dark-background"
  "slide-backgrounds-and-notes|2|advanced/slide-backgrounds-and-notes|gradient-background"
  "slide-backgrounds-and-notes|3|advanced/slide-backgrounds-and-notes|pattern-background"
  "slide-backgrounds-and-notes|4|advanced/slide-backgrounds-and-notes|picture-background"

  "tables|1|core/tables|basic-table"
  "tables|2|core/tables|cell-merging"
  "tables|3|core/tables|cell-formatting"
  "tables|4|core/tables|complete-example"

  "text-and-formatting|1|core/text-and-formatting|mixed-formatting"
  "text-and-formatting|2|core/text-and-formatting|bullets-and-numbered"
  "text-and-formatting|3|core/text-and-formatting|superscript-underlines"
  "text-and-formatting|4|core/text-and-formatting|putting-it-together"
)

# Compile the Swift PDF-to-PNG helper (once, cached in TEMP_DIR).
# Uses macOS CoreGraphics — no pip installs needed.
build_pdf2png() {
  PDF2PNG="$TEMP_DIR/pdf2png"
  if [[ -f "$PDF2PNG" ]]; then
    return
  fi

  echo "Compiling PDF-to-PNG helper..."
  swiftc -O -o "$PDF2PNG" - <<'SWIFT'
import Foundation
import CoreGraphics
import ImageIO

let args = CommandLine.arguments
guard args.count >= 3 else {
    fputs("Usage: pdf2png <input.pdf> <output_dir>\n", stderr)
    exit(1)
}

let pdfPath = args[1]
let outputDir = args[2]
let dpi: CGFloat = 96.0
let scale = dpi / 72.0

try? FileManager.default.createDirectory(
    atPath: outputDir, withIntermediateDirectories: true)

guard let pdfURL = CFURLCreateFromFileSystemRepresentation(
            nil, pdfPath, pdfPath.utf8.count, false),
      let pdfDoc = CGPDFDocument(pdfURL) else {
    fputs("ERROR: Could not open PDF: \(pdfPath)\n", stderr)
    exit(1)
}

let pageCount = pdfDoc.numberOfPages
for pageNum in 1...pageCount {
    guard let page = pdfDoc.page(at: pageNum) else { continue }
    let mediaBox = page.getBoxRect(.mediaBox)
    let width = Int(mediaBox.width * scale)
    let height = Int(mediaBox.height * scale)

    let colorSpace = CGColorSpaceCreateDeviceRGB()
    guard let context = CGContext(
        data: nil, width: width, height: height,
        bitsPerComponent: 8, bytesPerRow: width * 4,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else { continue }

    context.setFillColor(red: 1, green: 1, blue: 1, alpha: 1)
    context.fill(CGRect(x: 0, y: 0, width: width, height: height))
    context.scaleBy(x: scale, y: scale)
    context.drawPDFPage(page)

    guard let image = context.makeImage() else { continue }
    let outPath = (outputDir as NSString).appendingPathComponent("page-\(pageNum).png")
    guard let outURL = CFURLCreateFromFileSystemRepresentation(
                nil, outPath, outPath.utf8.count, false),
          let dest = CGImageDestinationCreateWithURL(
                outURL, "public.png" as CFString, 1, nil)
    else { continue }
    CGImageDestinationAddImage(dest, image, nil)
    CGImageDestinationFinalize(dest)
}
print("Rendered \(pageCount) pages to PNG")
SWIFT

  if [[ ! -f "$PDF2PNG" ]]; then
    echo "ERROR: Failed to compile pdf2png helper. Is Xcode CLT installed?"
    exit 1
  fi
}

# Convert a multi-page PDF to individual PNGs using the Swift helper.
# Usage: pdf_to_pngs <input.pdf> <output_dir>
# Creates output_dir/page-1.png, page-2.png, etc.
pdf_to_pngs() {
  "$PDF2PNG" "$1" "$2"
}

# Export a pptx to PDF via PowerPoint, convert pages to PNG, move needed slides.
# Args: pptx_name followed by pairs of (slide_num, output_path)
flush_batch() {
  local pptx_name="$1"
  shift
  local pptx_path="$INPUT_DIR/${pptx_name}.pptx"

  if [[ ! -f "$pptx_path" ]]; then
    echo "WARNING: $pptx_path not found, skipping"
    return
  fi

  echo "Exporting from $pptx_name.pptx..."

  local pdf_path="$TEMP_DIR/${pptx_name}.pdf"
  local pages_dir="$TEMP_DIR/${pptx_name}-pages"
  rm -f "$pdf_path"
  rm -rf "$pages_dir"

  # Step 1: Export to PDF via PowerPoint.
  # Uses the "save as PDF" AppleScript command with a POSIX file reference.
  # The file reference (not a bare string) is required for silent export.
  local as_output
  as_output=$(osascript 2>&1 <<EOF
tell application "Microsoft PowerPoint"
  activate
  open "$pptx_path"
  delay 0.5
  set activePres to active presentation
  save activePres in (POSIX file "$pdf_path") as save as PDF
  close active presentation saving no
end tell
EOF
  ) && true
  local as_exit=$?

  if [[ $as_exit -ne 0 ]]; then
    echo "  AppleScript failed (exit $as_exit): $as_output"
    return
  fi

  if [[ ! -f "$pdf_path" ]]; then
    echo "  PDF not created — export failed"
    if [[ -n "$as_output" ]]; then
      echo "  osascript output: $as_output"
    fi
    return
  fi

  # Step 2: Render PDF pages to individual PNGs
  pdf_to_pngs "$pdf_path" "$pages_dir"

  # Step 3: Move the specific slides we need to their final destinations
  while [[ $# -gt 0 ]]; do
    local sn="$1"
    local out="$2"
    shift 2
    mkdir -p "$(dirname "$out")"

    local page_png="$pages_dir/page-${sn}.png"
    if [[ -f "$page_png" ]]; then
      mv "$page_png" "$out"
      echo "  Slide $sn -> ${out#"$PROJECT_DIR"/}"
    else
      echo "  FAILED: page-${sn}.png not found"
    fi
  done

  rm -f "$pdf_path"
  rm -rf "$pages_dir"
}

echo "Exporting demo slides to PNG images..."
echo "Input:  $INPUT_DIR"
echo "Output: $ASSETS_DIR"
echo ""

mkdir -p "$TEMP_DIR"
build_pdf2png

# Generate all demo .pptx files
echo "Generating demo presentations..."
for demo in "$PROJECT_DIR"/demos/*.exs; do
  name="$(basename "$demo" .exs)"
  echo "  mix run demos/$name.exs"
  (cd "$PROJECT_DIR" && mix run "$demo")
done
echo ""

# Walk the sorted SLIDES array, batching by pptx name
current_pptx=""
batch_args=()

for entry in "${SLIDES[@]}"; do
  IFS='|' read -r pptx_name slide_num subdir img_name <<< "$entry"
  out_path="$ASSETS_DIR/$subdir/$img_name.png"

  if [[ "$pptx_name" != "$current_pptx" ]]; then
    # Flush previous batch
    if [[ -n "$current_pptx" ]]; then
      flush_batch "$current_pptx" "${batch_args[@]}"
      echo ""
    fi
    current_pptx="$pptx_name"
    batch_args=()
  fi

  batch_args+=("$slide_num" "$out_path")
done

# Flush final batch
if [[ -n "$current_pptx" ]]; then
  flush_batch "$current_pptx" "${batch_args[@]}"
  echo ""
fi

rm -rf "$TEMP_DIR"

# Optimize PNGs with pngquant if available (lossy palette quantization, ~60-80% savings)
if command -v pngquant &>/dev/null; then
  echo "Optimizing PNGs with pngquant..."
  find "$ASSETS_DIR" -name "*.png" -exec pngquant --force --ext .png --quality=65-90 --skip-if-larger {} \;
  echo ""
else
  echo "Tip: install pngquant (brew install pngquant) for smaller PNG output"
  echo ""
fi

total=$(find "$ASSETS_DIR" -name "*.png" | wc -l | tr -d ' ')
echo "Done. Exported $total PNG images to guides/assets/"
