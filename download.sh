#!/bin/bash

mkdir -p DYSORDER
cd DYSORDER

declare -A files=(
  ["LowNet.sh"]="https://raw.githubusercontent.com/simplyYan/DYSORDER/refs/heads/main/tools/LowNet/LowNet.sh"
  ["NetDelusyon.sh"]="https://raw.githubusercontent.com/simplyYan/DYSORDER/refs/heads/main/tools/NetDelusyion/NetDelusyon.sh"
  ["mrchainsaw.sh"]="https://raw.githubusercontent.com/simplyYan/DYSORDER/refs/heads/main/tools/MrChainsaw/mrchainsaw.sh"
  ["MrSpecter.sh"]="https://raw.githubusercontent.com/simplyYan/DYSORDER/refs/heads/main/tools/MrSpecter/MrSpecter.sh"
)

# Baixa cada arquivo
for filename in "${!files[@]}"; do
  echo "Downloading $filename..."
  curl -sSL "${files[$filename]}" -o "$filename"
  chmod +x "$filename"
  sudo cp "$filename" /usr/local/bin/
done

echo "All DYSØRDER tools have been downloaded and globalized. All ready to use, in any directory :)"
