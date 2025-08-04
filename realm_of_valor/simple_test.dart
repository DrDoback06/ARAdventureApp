// Simple test for core models without Flutter dependencies
import 'lib/models/battle_model.dart';
import 'lib/models/card_model.dart';

void main() {
  print('Testing core model compilation...');
  
  // Test ActionCard creation
  try {
    final actionCard = ActionCard(
      name: 'Test Card',
      description: 'A test card',
      type: ActionCardType.damage,
      effect: 'test_effect',
      cost: 3,
    );
    print('✅ ActionCard created successfully');
    print('   Name: ${actionCard.name}');
    print('   Cost: ${actionCard.cost}');
  } catch (e) {
    print('❌ ActionCard creation failed: $e');
  }
  
  // Test AttackCard creation
  try {
    final attackCard = AttackCard(
      characterId: 'test-character',
      baseDamage: 25,
      damageModifiers: {'weapon_bonus': 5},
    );
    print('✅ AttackCard created successfully');
    print('   Total damage: ${attackCard.totalDamage}');
  } catch (e) {
    print('❌ AttackCard creation failed: $e');
  }
  
  // Test SkillCard creation
  try {
    final skillCard = SkillCard(
      skillId: 'fireball',
      characterId: 'test-character',
      name: 'Fireball',
      description: 'Deal 35 fire damage',
      baseManaCost: 6,
      baseDamage: 35,
      skillType: 'active',
      skillModifiers: {'damage_bonus': 10},
    );
    print('✅ SkillCard created successfully');
    print('   Total damage: ${skillCard.totalDamage}');
    print('   Total mana cost: ${skillCard.totalManaCost}');
  } catch (e) {
    print('❌ SkillCard creation failed: $e');
  }
  
  print('\n🎉 Core model compilation tests completed!');
} 