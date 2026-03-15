#!/bin/bash

# Dead Tide Setup Script
# Run this to initialize git and prepare for GitHub push

echo "Dead Tide - Setting up repository..."

cd /home/dockarr/.openclaw/workspace/deadtide

# Initialize git
git init

# Add all files
git add .

# Initial commit
git commit -m "Initial commit: Dead Tide project structure and core systems

- Project structure with autoload managers (GameManager, ZombieManager, EventBus)
- Core systems: player controller, zombie AI, weapon system
- Main scene with prototype map
- Input controls configured
- Documentation and README"

echo ""
echo "✅ Repository initialized!"
echo ""
echo "Next steps:"
echo "1. Create a new GitHub repository called 'deadtide'"
echo "2. Run these commands to push to GitHub:"
echo ""
echo "   git remote add origin https://github.com/EarthDeparture/deadtide.git"
echo "   git branch -M main"
echo "   git push -u origin main"
echo ""
echo "3. Clone the repository on your Mac:"
echo "   git clone https://github.com/EarthDeparture/deadtide.git"
echo "   cd deadtide"
echo "   open -a Godot ."
