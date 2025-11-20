#!/usr/bin/env python3
import asyncio
import logging
from src.ai_evolution.evolution_engine import AIEvolutionEngine, SelfHealingSystem
from src.code_analysis.code_scanner import AICodeScanner, GitHubCodeScanner
from src.testing.ai_test_engine import AITestEngine, ContinuousTesting

def main():
    """Start AI evolution and self-healing systems"""
    
    logging.basicConfig(level=logging.INFO)
    
    # Initialize systems
    evolution_engine = AIEvolutionEngine({
        'mutation_rate': 0.15,
        'population_size': 10,
        'max_generations': 1000
    })
    
    healing_system = SelfHealingSystem({
        'monitor_interval': 300,
        'auto_heal': True,
        'backup_before_changes': True
    })
    
    code_scanner = AICodeScanner()
    test_engine = AITestEngine({})
    
    # Start continuous processes
    processes = [
        evolution_engine.start_continuous_evolution(),
        healing_system.monitor_and_heal(),
        test_engine.start_continuous_testing()
    ]
    
    # Run all processes
    asyncio.gather(*processes)

if __name__ == '__main__':
    main()
