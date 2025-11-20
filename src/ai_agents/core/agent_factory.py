from typing import Dict, Any, List
from .base_agent import BaseAgent
from ..synthetic_intelligence.reasoning_engine import ReasoningEngine
from ..strategic_intelligence.strategic_planner import StrategicPlanner
from ..deep_agents.neural_architectures import DeepAgentArchitecture

class AgentFactory:
    def __init__(self):
        self.agent_registry = {}
        
    def create_agent(self, 
                    agent_type: str,
                    capabilities: List[str],
                    config: Dict[str, Any]) -> BaseAgent:
        """Create AI agents with specified capabilities"""
        
        if agent_type == "strategic":
            return self._create_strategic_agent(capabilities, config)
        elif agent_type == "synthetic":
            return self._create_synthetic_agent(capabilities, config)
        elif agent_type == "deep":
            return self._create_deep_agent(capabilities, config)
        else:
            raise ValueError(f"Unknown agent type: {agent_type}")
    
    def _create_strategic_agent(self, capabilities: List[str], config: Dict[str, Any]):
        strategic_planner = StrategicPlanner(config.get('strategy_params', {}))
        return StrategicAgent(capabilities, strategic_planner, config)
    
    def _create_synthetic_agent(self, capabilities: List[str], config: Dict[str, Any]):
        reasoning_engine = ReasoningEngine(config.get('reasoning_params', {}))
        return SyntheticAgent(capabilities, reasoning_engine, config)
    
    def _create_deep_agent(self, capabilities: List[str], config: Dict[str, Any]):
        neural_arch = DeepAgentArchitecture(config.get('model_params', {}))
        return DeepAgent(capabilities, neural_arch, config)
