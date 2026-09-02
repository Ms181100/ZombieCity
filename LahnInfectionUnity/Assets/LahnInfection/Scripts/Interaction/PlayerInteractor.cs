using UnityEngine;
using UnityEngine.InputSystem;

namespace LahnInfection.Interaction
{
    public sealed class PlayerInteractor : MonoBehaviour
    {
        [SerializeField] private Camera playerCamera;
        [SerializeField] private InputActionReference interactAction;
        [SerializeField] private float range = 2.6f;
        [SerializeField] private LayerMask interactionMask;
        private readonly RaycastHit[] hits = new RaycastHit[4];
        private IInteractable current;
        public string CurrentPrompt => current?.Prompt ?? string.Empty;

        private void OnEnable()
        {
            if (interactAction == null) return;
            interactAction.action.Enable();
            interactAction.action.performed += OnInteract;
        }

        private void OnDisable()
        {
            if (interactAction == null) return;
            interactAction.action.performed -= OnInteract;
            interactAction.action.Disable();
        }

        private void Update()
        {
            current = null;
            if (playerCamera == null) return;
            int count = Physics.RaycastNonAlloc(playerCamera.transform.position, playerCamera.transform.forward,
                hits, range, interactionMask, QueryTriggerInteraction.Collide);
            float nearest = float.MaxValue;
            for (int i = 0; i < count; i++)
            {
                WorldInteractable candidate = hits[i].collider.GetComponentInParent<WorldInteractable>();
                if (candidate == null || !candidate.CanInteract(gameObject) || hits[i].distance >= nearest) continue;
                current = candidate;
                nearest = hits[i].distance;
            }
        }

        public void InteractFromTouchButton()
        {
            if (current != null && current.CanInteract(gameObject)) current.Interact(gameObject);
        }

        private void OnInteract(InputAction.CallbackContext context) => InteractFromTouchButton();
    }
}
