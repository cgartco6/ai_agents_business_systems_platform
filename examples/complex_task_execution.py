from src.ai_agents.core.agent_factory import AgentFactory
from src.ai_agents.helpers.coordinator import TaskCoordinator
from src.ai_agents.communication.message_broker import MessageBroker

def main():
    # Initialize components
    agent_factory = AgentFactory()
    message_broker = MessageBroker()
    coordinator = TaskCoordinator(message_broker)
    
    # Create specialized agents
    strategic_agent = agent_factory.create_agent(
        "strategic",
        capabilities=["planning", "risk_assessment", "resource_allocation"],
        config={"strategy_params": {"horizon": 50}}
    )
    
    synthetic_agent = agent_factory.create_agent(
        "synthetic", 
        capabilities=["reasoning", "knowledge_synthesis", "creative_generation"],
        config={"reasoning_params": {"max_iterations": 100}}
    )
    
    deep_agent = agent_factory.create_agent(
        "deep",
        capabilities=["pattern_recognition", "prediction", "optimization"],
        config={"model_params": {"hidden_size": 1024}}
    )
    
    # Define complex task
    complex_task = {
        "id": "task_001",
        "description": "Develop strategic market entry plan with risk assessment",
        "constraints": {"budget": 1000000, "timeline": 90},
        "objectives": ["market_analysis", "risk_assessment", "entry_strategy"]
    }
    
    # Execute coordinated task
    available_agents = [strategic_agent, synthetic_agent, deep_agent]
    result = coordinator.orchestrate_complex_task(complex_task, available_agents)
    
    print("Task completed with result:", result)

if __name__ == "__main__":
    main()
