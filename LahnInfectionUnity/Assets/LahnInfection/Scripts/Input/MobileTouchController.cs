using LahnInfection.Core;
using UnityEngine;
using UnityEngine.InputSystem;

namespace LahnInfection.Input
{
    [RequireComponent(typeof(CharacterController))]
    public sealed class MobileTouchController : MonoBehaviour
    {
        public enum AimAssistStrength { Off, Medium, Strong }

        [Header("Input System")]
        [SerializeField] private InputActionReference moveAction;
        [SerializeField] private InputActionReference lookAction;
        [SerializeField] private InputActionReference fireAction;
        [SerializeField] private InputActionReference meleeAction;
        [SerializeField] private InputActionReference crouchAction;
        [SerializeField] private InputActionReference dodgeAction;
        [SerializeField] private InputActionReference sprintAction;

        [Header("Bewegung")]
        [SerializeField] private Transform cameraPivot;
        [SerializeField] private float walkSpeed = 3.2f;
        [SerializeField] private float sprintSpeed = 5.6f;
        [SerializeField] private float crouchSpeed = 1.8f;
        [SerializeField] private float rotationSpeed = 14f;
        [SerializeField] private float gravity = -24f;
        [SerializeField] private float dodgeDistance = 3.2f;
        [SerializeField] private float dodgeDuration = 0.24f;

        [Header("Kamera")]
        [SerializeField] private float lookSensitivity = 0.12f;
        [SerializeField] private float minPitch = -45f;
        [SerializeField] private float maxPitch = 65f;

        [Header("Kampf")]
        [SerializeField] private AimAssistStrength aimAssist = AimAssistStrength.Medium;
        [SerializeField] private LayerMask enemyMask;
        [SerializeField] private float aimRadius = 8f;
        [SerializeField] private float aimAngle = 18f;
        [SerializeField] private float shotNoiseRadius = 35f;

        private readonly Collider[] aimHits = new Collider[24];
        private CharacterController controller;
        private Vector2 moveInput;
        private Vector2 lookInput;
        private float verticalVelocity;
        private float pitch;
        private float dodgeTimer;
        private Vector3 dodgeDirection;
        private bool crouched;

        public event System.Action FireRequested;
        public event System.Action MeleeRequested;

        private void Awake()
        {
            controller = GetComponent<CharacterController>();
        }

        private void OnEnable()
        {
            Enable(moveAction); Enable(lookAction); Enable(fireAction); Enable(meleeAction);
            Enable(crouchAction); Enable(dodgeAction); Enable(sprintAction);
            if (fireAction != null) fireAction.action.performed += OnFire;
            if (meleeAction != null) meleeAction.action.performed += OnMelee;
            if (crouchAction != null) crouchAction.action.performed += OnCrouch;
            if (dodgeAction != null) dodgeAction.action.performed += OnDodge;
        }

        private void OnDisable()
        {
            if (fireAction != null) fireAction.action.performed -= OnFire;
            if (meleeAction != null) meleeAction.action.performed -= OnMelee;
            if (crouchAction != null) crouchAction.action.performed -= OnCrouch;
            if (dodgeAction != null) dodgeAction.action.performed -= OnDodge;
            Disable(moveAction); Disable(lookAction); Disable(fireAction); Disable(meleeAction);
            Disable(crouchAction); Disable(dodgeAction); Disable(sprintAction);
        }

        private void Update()
        {
            moveInput = moveAction == null ? Vector2.zero : moveAction.action.ReadValue<Vector2>();
            lookInput = lookAction == null ? Vector2.zero : lookAction.action.ReadValue<Vector2>();
            UpdateCamera();
            UpdateMovement(Time.deltaTime);
        }

        private void UpdateCamera()
        {
            transform.Rotate(0f, lookInput.x * lookSensitivity, 0f, Space.World);
            pitch = Mathf.Clamp(pitch - lookInput.y * lookSensitivity, minPitch, maxPitch);
            if (cameraPivot != null) cameraPivot.localRotation = Quaternion.Euler(pitch, 0f, 0f);
        }

        private void UpdateMovement(float deltaTime)
        {
            if (dodgeTimer > 0f)
            {
                dodgeTimer -= deltaTime;
                controller.Move(dodgeDirection * (dodgeDistance / dodgeDuration) * deltaTime);
                return;
            }

            Vector3 direction = transform.right * moveInput.x + transform.forward * moveInput.y;
            if (direction.sqrMagnitude > 1f) direction.Normalize();
            bool sprinting = !crouched && (moveInput.magnitude > 0.92f ||
                             (sprintAction != null && sprintAction.action.IsPressed()));
            float speed = crouched ? crouchSpeed : sprinting ? sprintSpeed : walkSpeed;
            verticalVelocity = controller.isGrounded ? -2f : verticalVelocity + gravity * deltaTime;
            direction.y = verticalVelocity;
            controller.Move(direction * speed * deltaTime);

            Vector3 planar = new Vector3(direction.x, 0f, direction.z);
            if (planar.sqrMagnitude > 0.02f)
            {
                transform.rotation = Quaternion.Slerp(transform.rotation,
                    Quaternion.LookRotation(planar), rotationSpeed * deltaTime);
            }
        }

        public Transform FindAimTarget(Vector3 origin, Vector3 forward)
        {
            if (aimAssist == AimAssistStrength.Off) return null;
            float allowedAngle = aimAssist == AimAssistStrength.Strong ? aimAngle * 1.65f : aimAngle;
            int count = Physics.OverlapSphereNonAlloc(origin, aimRadius, aimHits, enemyMask,
                QueryTriggerInteraction.Ignore);
            Transform best = null;
            float bestScore = float.MaxValue;
            for (int i = 0; i < count; i++)
            {
                Vector3 toTarget = aimHits[i].bounds.center - origin;
                float angle = Vector3.Angle(forward, toTarget);
                if (angle > allowedAngle) continue;
                float score = angle * 3f + toTarget.sqrMagnitude * 0.05f;
                if (score < bestScore) { bestScore = score; best = aimHits[i].transform; }
            }
            return best;
        }

        public void SetAimAssist(int strength)
        {
            aimAssist = (AimAssistStrength)Mathf.Clamp(strength, 0, 2);
        }

        private void OnFire(InputAction.CallbackContext context)
        {
            NoiseSystem.Emit(transform.position, shotNoiseRadius, gameObject);
            FireRequested?.Invoke();
        }

        private void OnMelee(InputAction.CallbackContext context) => MeleeRequested?.Invoke();
        private void OnCrouch(InputAction.CallbackContext context) => crouched = !crouched;

        private void OnDodge(InputAction.CallbackContext context)
        {
            if (dodgeTimer > 0f) return;
            Vector3 inputDirection = transform.right * moveInput.x + transform.forward * moveInput.y;
            dodgeDirection = inputDirection.sqrMagnitude < 0.05f ? -transform.forward : inputDirection.normalized;
            dodgeTimer = dodgeDuration;
        }

        private static void Enable(InputActionReference reference) { if (reference != null) reference.action.Enable(); }
        private static void Disable(InputActionReference reference) { if (reference != null) reference.action.Disable(); }
    }
}
