from typing import Dict, List, Any
from decimal import Decimal
import datetime

class WeeklyPayoutManager:
    def __init__(self, config: Dict[str, Any]):
        self.config = config
        self.distribution = {
            'owner_fnb': Decimal('0.40'),  # 40%
            'african_bank': Decimal('0.15'),  # 15%
            'reserve_fnb': Decimal('0.20'),  # 20%
            'ai_fnb': Decimal('0.20'),  # 20%
            # 5% stays in account automatically
        }
        
    def calculate_weekly_payout(self, total_revenue: Decimal) -> Dict[str, Decimal]:
        """Calculate weekly payout distribution"""
        
        # Deduct 5% for account growth
        payout_amount = total_revenue * Decimal('0.95')
        reserve_amount = total_revenue * Decimal('0.05')
        
        distributions = {}
        for account, percentage in self.distribution.items():
            distributions[account] = payout_amount * percentage
            
        # Add reserve to tracking
        distributions['reserve_growth'] = reserve_amount
        
        return distributions
    
    def execute_payouts(self, distributions: Dict[str, Decimal]) -> bool:
        """Execute payouts to respective accounts"""
        
        try:
            # FNB Payout (40%)
            self._transfer_to_fnb(distributions['owner_fnb'])
            
            # African Bank Payout (15%)
            self._transfer_to_african_bank(distributions['african_bank'])
            
            # Reserve FNB (20%)
            self._transfer_to_reserve(distributions['reserve_fnb'])
            
            # AI Development FNB (20%)
            self._transfer_to_ai_account(distributions['ai_fnb'])
            
            # Log reserve growth separately
            self._track_reserve_growth(distributions['reserve_growth'])
            
            return True
        except Exception as e:
            self._log_payout_error(e)
            return False
