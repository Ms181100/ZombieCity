using LahnInfection.Core;
using LahnInfection.Inventory;
using LahnInfection.Missions;
using UnityEngine;

namespace LahnInfection.Interaction
{
    public interface IInteractable
    {
        string Prompt { get; }
        bool CanInteract(GameObject actor);
        void Interact(GameObject actor);
    }

    public sealed class WorldInteractable : MonoBehaviour, IInteractable
    {
        public enum InteractionType { Loot, Door, Generator, Radio, SafehouseBed, NoiseBottle }

        [SerializeField] private InteractionType type;
        [SerializeField] private string prompt = "Interagieren";
        [SerializeField] private string missionEventId;
        [SerializeField] private ItemDefinition lootItem;
        [SerializeField] private int lootAmount = 1;
        [SerializeField] private Animator animator;
        [SerializeField] private LastSignalMission mission;
        [SerializeField] private SafehouseSaveSystem saveSystem;
        [SerializeField] private float bottleNoiseRadius = 22f;
        [SerializeField] private bool singleUse = true;
        private bool used;

        public string Prompt => prompt;
        public bool CanInteract(GameObject actor) => !used && actor != null;

        public void Interact(GameObject actor)
        {
            if (!CanInteract(actor)) return;
            switch (type)
            {
                case InteractionType.Loot:
                    InventorySystem inventory = actor.GetComponent<InventorySystem>();
                    if (inventory == null || !inventory.TryAdd(lootItem, lootAmount)) return;
                    break;
                case InteractionType.Door:
                    if (animator != null) animator.SetTrigger("Toggle");
                    break;
                case InteractionType.Generator:
                    if (animator != null) animator.SetTrigger("Start");
                    NoiseSystem.Emit(transform.position, 30f, gameObject);
                    break;
                case InteractionType.Radio:
                    if (animator != null) animator.SetTrigger("Transmit");
                    break;
                case InteractionType.SafehouseBed:
                    if (saveSystem != null) saveSystem.Save(actor.transform, mission);
                    break;
                case InteractionType.NoiseBottle:
                    NoiseSystem.Emit(transform.position, bottleNoiseRadius, gameObject);
                    break;
            }
            if (mission != null && !string.IsNullOrWhiteSpace(missionEventId)) mission.TryAdvance(missionEventId);
            if (singleUse) used = true;
        }
    }
}
