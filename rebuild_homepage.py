#!/usr/bin/env python3
"""Rebuild homepage with animated sections"""

import os

target_file = '/Users/jai/Workspace/apps/active/auracraft/app/views/home/index.html.erb'

# Read original file
with open(target_file, 'r') as f:
    original = f.read()

# CSS animations to insert after line 2
css_animations = '''
<!-- CSS Animations - Cross Browser Support -->
<style>
  @keyframes float-slow {
    0%, 100% { transform: translateY(0px) translateX(0px); }
    50% { transform: translateY(-20px) translateX(10px); }
  }
  @keyframes float-medium {
    0%, 100% { transform: translateY(0px) translateX(0px); }
    50% { transform: translateY(-15px) translateX(-15px); }
  }
  @keyframes float-fast {
    0%, 100% { transform: translateY(0px) translateX(0px); }
    50% { transform: translateY(-25px) translateX(5px); }
  }
  @keyframes sparkle {
    0%, 100% { opacity: 0.3; transform: scale(0.8); }
    50% { opacity: 1; transform: scale(1.2); }
  }
  @keyframes rotate-slow {
    0% { transform: rotate(0deg); }
    100% { transform: rotate(360deg); }
  }
  @keyframes pulse-glow {
    0%, 100% { filter: drop-shadow(0 0 5px rgba(225, 29, 72, 0.3)); }
    50% { filter: drop-shadow(0 0 20px rgba(225, 29, 72, 0.6)); }
  }
  @keyframes shimmer {
    0% { background-position: -200% 0; }
    100% { background-position: 200% 0; }
  }
  @keyframes heart-beat {
    0%, 100% { transform: scale(1); }
    50% { transform: scale(1.1); }
  }
  @keyframes bounce-subtle {
    0%, 100% { transform: translateY(0); }
    50% { transform: translateY(-10px); }
  }
  .animate-float-slow { 
    animation: float-slow 8s ease-in-out infinite;
    -webkit-animation: float-slow 8s ease-in-out infinite;
  }
  .animate-float-medium { 
    animation: float-medium 6s ease-in-out infinite;
    -webkit-animation: float-medium 6s ease-in-out infinite;
  }
  .animate-float-fast { 
    animation: float-fast 4s ease-in-out infinite;
    -webkit-animation: float-fast 4s ease-in-out infinite;
  }
  .animate-sparkle { 
    animation: sparkle 2s ease-in-out infinite;
    -webkit-animation: sparkle 2s ease-in-out infinite;
  }
  .animate-rotate-slow { 
    animation: rotate-slow 20s linear infinite;
    -webkit-animation: rotate-slow 20s linear infinite;
  }
  .animate-pulse-glow { 
    animation: pulse-glow 3s ease-in-out infinite;
    -webkit-animation: pulse-glow 3s ease-in-out infinite;
  }
  .animate-shimmer {
    background: linear-gradient(90deg, transparent 0%, rgba(255,255,255,0.4) 50%, transparent 100%);
    background-size: 200% 100%;
    animation: shimmer 3s ease-in-out infinite;
    -webkit-animation: shimmer 3s ease-in-out infinite;
  }
  .animate-heart-beat {
    animation: heart-beat 1.5s ease-in-out infinite;
    -webkit-animation: heart-beat 1.5s ease-in-out infinite;
  }
  .animate-bounce-subtle {
    animation: bounce-subtle 2s ease-in-out infinite;
    -webkit-animation: bounce-subtle 2s ease-in-out infinite;
  }
</style>
'''

# Update page title
original = original.replace(
    '<% content_for(:title) { "Jewellery & Traditional Wear" } %>',
    '<% content_for(:title) { "Artificial Jewellery, Gifts & Ethnic Wear" } %>'
)

# Update hero subtitle
original = original.replace(
    'Curated picks for weddings, festivals, everyday elegance, and gifting',
    'Exquisite artificial jewellery, thoughtful gifts, and beautiful ethnic wear for every occasion'
)

# Insert CSS after line 2
lines = original.split('\n')
lines.insert(2, css_animations)
original = '\n'.join(lines)

print("Step 1: CSS animations and basic updates added")

with open(target_file, 'w') as f:
    f.write(original)

print(f"File updated: {target_file}")
print(f"New line count: {len(original.split(chr(10)))}")
