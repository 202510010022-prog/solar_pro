#!/usr/bin/env python3
"""
Script para converter PNG em ICO para Windows executável.
Uso: python convert_icon.py
"""

from pathlib import Path
from PIL import Image

def convert_png_to_ico():
    """Converte app_icon.png para app_icon.ico"""
    
    source_path = Path(__file__).parent / "desktop_app_qt" / "assets" / "app_icon.png"
    output_path = Path(__file__).parent / "desktop_app_qt" / "assets" / "app_icon.ico"
    
    if not source_path.exists():
        print(f"❌ Erro: {source_path} não encontrado")
        return False
    
    try:
        # Abrir imagem PNG
        img = Image.open(source_path)
        
        # Converter para RGB se estiver em RGBA
        if img.mode in ("RGBA", "LA", "P"):
            bg = Image.new("RGB", img.size, (255, 255, 255))
            if img.mode == "P":
                img = img.convert("RGBA")
            bg.paste(img, mask=img.split()[-1] if img.mode in ("RGBA", "LA") else None)
            img = bg
        
        # Redimensionar para tamanhos padrão de ICO
        sizes = [(16, 16), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)]
        icon_images = []
        
        for size in sizes:
            resized = img.resize(size, Image.Resampling.LANCZOS)
            icon_images.append(resized)
        
        # Salvar como ICO com múltiplos tamanhos
        icon_images[0].save(
            output_path,
            format="ICO",
            sizes=[img.size for img in icon_images]
        )
        
        print(f"✅ Ícone criado com sucesso: {output_path}")
        print(f"   Tamanhos incluídos: {', '.join(f'{s[0]}x{s[1]}' for s in sizes)}")
        return True
        
    except Exception as e:
        print(f"❌ Erro ao converter ícone: {e}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    convert_png_to_ico()
