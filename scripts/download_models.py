#!/usr/bin/env python3
# scripts/download_models.py - Download AI models for both systems

import os
import requests
import torch
from pathlib import Path
import argparse
from tqdm import tqdm

def download_file(url, filename):
    """Download file with progress bar"""
    response = requests.get(url, stream=True)
    total_size = int(response.headers.get('content-length', 0))
    
    with open(filename, 'wb') as file, tqdm(
        desc=filename.name,
        total=total_size,
        unit='iB',
        unit_scale=True,
        unit_divisor=1024,
    ) as bar:
        for data in response.iter_content(chunk_size=1024):
            size = file.write(data)
            bar.update(size)

def main():
    parser = argparse.ArgumentParser(description='Download AI models')
    parser.add_argument('--cpu-only', action='store_true', help='Download CPU-only models')
    args = parser.parse_args()
    
    # Create model directories
    model_dir = Path('data/models')
    model_dir.mkdir(parents=True, exist_ok=True)
    
    models_to_download = [
        {
            'name': 'musicgen-small',
            'url': 'https://huggingface.co/facebook/musicgen-small/resolve/main/pytorch_model.bin',
            'filename': model_dir / 'musicgen-small.bin'
        },
        {
            'name': 'whisper-small',
            'url': 'https://huggingface.co/openai/whisper-small/resolve/main/pytorch_model.bin',
            'filename': model_dir / 'whisper-small.bin'
        },
        {
            'name': 'stable-diffusion-v1-5',
            'url': 'https://huggingface.co/runwayml/stable-diffusion-v1-5/resolve/main/v1-5-pruned.ckpt',
            'filename': model_dir / 'stable-diffusion-v1-5.ckpt'
        }
    ]
    
    print("🤖 Downloading AI models...")
    
    for model in models_to_download:
        if not model['filename'].exists():
            print(f"📥 Downloading {model['name']}...")
            try:
                download_file(model['url'], model['filename'])
            except Exception as e:
                print(f"❌ Failed to download {model['name']}: {e}")
        else:
            print(f"✅ {model['name']} already exists")
    
    # Download smaller models for i3 system
    if args.cpu_only:
        light_models = [
            {
                'name': 'tiny-llm',
                'url': 'https://huggingface.co/TinyLlama/TinyLlama-1.1B/resolve/main/pytorch_model.bin',
                'filename': model_dir / 'tiny-llm.bin'
            }
        ]
        
        for model in light_models:
            if not model['filename'].exists():
                print(f"📥 Downloading light model {model['name']}...")
                try:
                    download_file(model['url'], model['filename'])
                except Exception as e:
                    print(f"❌ Failed to download {model['name']}: {e}")
            else:
                print(f"✅ {model['name']} already exists")
    
    print("✅ Model download completed!")

if __name__ == '__main__':
    main()
