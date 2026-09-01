using System;
using System.Collections.Generic;
using UnityEngine;

namespace LahnInfection.Inventory
{
    public enum ItemType { Material, Medicine, Food, Ammunition, Weapon, Tool, Quest }

    [CreateAssetMenu(menuName = "Lahn Infection/Item", fileName = "Item_")]
    public sealed class ItemDefinition : ScriptableObject
    {
        public string id;
        public string displayName;
        public ItemType type;
        [Min(0f)] public float weight = 0.1f;
        [Min(1)] public int maxStack = 1;
        [Range(0, 100)] public int defaultDurability = 100;
        public Sprite icon;
    }

    [Serializable]
    public struct Ingredient
    {
        public ItemDefinition item;
        [Min(1)] public int amount;
    }

    [CreateAssetMenu(menuName = "Lahn Infection/Crafting Recipe", fileName = "Recipe_")]
    public sealed class CraftingRecipe : ScriptableObject
    {
        public Ingredient[] ingredients;
        public ItemDefinition result;
        [Min(1)] public int resultAmount = 1;
        public bool requiresWorkbench;
    }

    [Serializable]
    public sealed class InventorySlot
    {
        public ItemDefinition item;
        public int amount;
        public int durability;
        public bool IsEmpty => item == null || amount <= 0;
        public void Clear() { item = null; amount = 0; durability = 0; }
    }

    public sealed class InventorySystem : MonoBehaviour
    {
        [SerializeField, Min(1)] private int slotCount = 24;
        [SerializeField, Min(1f)] private float maximumWeight = 30f;
        [SerializeField] private List<InventorySlot> slots = new List<InventorySlot>(24);

        public IReadOnlyList<InventorySlot> Slots => slots;
        public float CurrentWeight { get; private set; }
        public float MaximumWeight => maximumWeight;
        public event Action Changed;

        private void Awake()
        {
            while (slots.Count < slotCount) slots.Add(new InventorySlot());
            if (slots.Count > slotCount) slots.RemoveRange(slotCount, slots.Count - slotCount);
            RecalculateWeight();
        }

        public bool TryAdd(ItemDefinition item, int amount, int durability = -1)
        {
            if (item == null || amount <= 0) return false;
            if (CurrentWeight + item.weight * amount > maximumWeight + 0.001f) return false;
            int remaining = amount;
            if (item.maxStack > 1)
            {
                for (int i = 0; i < slots.Count && remaining > 0; i++)
                {
                    InventorySlot slot = slots[i];
                    if (slot.item != item || slot.amount >= item.maxStack) continue;
                    int moved = Mathf.Min(remaining, item.maxStack - slot.amount);
                    slot.amount += moved; remaining -= moved;
                }
            }
            for (int i = 0; i < slots.Count && remaining > 0; i++)
            {
                InventorySlot slot = slots[i];
                if (!slot.IsEmpty) continue;
                int moved = Mathf.Min(remaining, Mathf.Max(1, item.maxStack));
                slot.item = item; slot.amount = moved;
                slot.durability = durability < 0 ? item.defaultDurability : Mathf.Clamp(durability, 0, 100);
                remaining -= moved;
            }
            if (remaining > 0) { Remove(item, amount - remaining); return false; }
            RecalculateWeight(); Changed?.Invoke(); return true;
        }

        public bool Remove(ItemDefinition item, int amount)
        {
            if (Count(item) < amount || amount <= 0) return false;
            int remaining = amount;
            for (int i = slots.Count - 1; i >= 0 && remaining > 0; i--)
            {
                InventorySlot slot = slots[i];
                if (slot.item != item) continue;
                int removed = Mathf.Min(remaining, slot.amount);
                slot.amount -= removed; remaining -= removed;
                if (slot.amount <= 0) slot.Clear();
            }
            RecalculateWeight(); Changed?.Invoke(); return true;
        }

        public int Count(ItemDefinition item)
        {
            int total = 0;
            for (int i = 0; i < slots.Count; i++) if (slots[i].item == item) total += slots[i].amount;
            return total;
        }

        public bool CanCraft(CraftingRecipe recipe, bool atWorkbench)
        {
            if (recipe == null || recipe.result == null || (recipe.requiresWorkbench && !atWorkbench)) return false;
            for (int i = 0; i < recipe.ingredients.Length; i++)
                if (Count(recipe.ingredients[i].item) < recipe.ingredients[i].amount) return false;
            float usedWeight = 0f;
            for (int i = 0; i < recipe.ingredients.Length; i++)
                usedWeight += recipe.ingredients[i].item.weight * recipe.ingredients[i].amount;
            return CurrentWeight - usedWeight + recipe.result.weight * recipe.resultAmount <= maximumWeight;
        }

        public bool TryCraft(CraftingRecipe recipe, bool atWorkbench)
        {
            if (!CanCraft(recipe, atWorkbench)) return false;
            for (int i = 0; i < recipe.ingredients.Length; i++)
                Remove(recipe.ingredients[i].item, recipe.ingredients[i].amount);
            return TryAdd(recipe.result, recipe.resultAmount);
        }

        public bool DamageItem(int slotIndex, int amount)
        {
            if (slotIndex < 0 || slotIndex >= slots.Count || slots[slotIndex].IsEmpty) return false;
            InventorySlot slot = slots[slotIndex];
            slot.durability = Mathf.Max(0, slot.durability - Mathf.Max(0, amount));
            if (slot.durability == 0) slot.Clear();
            RecalculateWeight(); Changed?.Invoke(); return true;
        }

        private void RecalculateWeight()
        {
            float total = 0f;
            for (int i = 0; i < slots.Count; i++)
                if (!slots[i].IsEmpty) total += slots[i].item.weight * slots[i].amount;
            CurrentWeight = total;
        }
    }
}
