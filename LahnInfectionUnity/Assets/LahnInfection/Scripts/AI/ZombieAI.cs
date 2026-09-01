using LahnInfection.Core;
using UnityEngine;
using UnityEngine.AI;

namespace LahnInfection.AI
{
    [RequireComponent(typeof(NavMeshAgent))]
    public sealed class ZombieAI : MonoBehaviour
    {
        public enum ZombieType { Schlurfer, Renner, Waechter }
        private enum State { Idle, Patrol, Investigate, Chase, Attack, Dead }

        [SerializeField] private ZombieType type;
        [SerializeField] private Transform target;
        [SerializeField] private Transform[] patrolPoints;
        [SerializeField] private LayerMask sightBlockingMask;
        [SerializeField] private float sightDistance = 18f;
        [SerializeField] private float sightAngle = 95f;
        [SerializeField] private float attackDistance = 1.6f;
        [SerializeField] private float attackCooldown = 1.15f;
        [SerializeField] private int maxHealth = 100;
        [SerializeField] private int damage = 15;
        [SerializeField] private float guardianAlarmRadius = 40f;

        private NavMeshAgent agent;
        private State state;
        private Vector3 investigatePosition;
        private int patrolIndex;
        private int health;
        private float nextSenseTime;
        private float nextAttackTime;
        private bool guardianAlarmUsed;

        public ZombieType Type => type;
        public bool IsDead => state == State.Dead;

        private void Awake()
        {
            agent = GetComponent<NavMeshAgent>();
            ApplyTypeValues();
            health = maxHealth;
            state = patrolPoints != null && patrolPoints.Length > 0 ? State.Patrol : State.Idle;
        }

        private void OnEnable() => NoiseSystem.Emitted += OnNoise;
        private void OnDisable() => NoiseSystem.Emitted -= OnNoise;

        private void Update()
        {
            if (state == State.Dead || target == null) return;
            if (Time.time >= nextSenseTime)
            {
                nextSenseTime = Time.time + 0.18f;
                if (CanSeeTarget()) EnterChase();
            }

            switch (state)
            {
                case State.Patrol: UpdatePatrol(); break;
                case State.Investigate: UpdateInvestigate(); break;
                case State.Chase: UpdateChase(); break;
                case State.Attack: UpdateAttack(); break;
            }
        }

        public void SetTarget(Transform newTarget) => target = newTarget;

        public void ReceiveDamage(int amount)
        {
            if (state == State.Dead) return;
            health -= Mathf.Max(0, amount);
            if (health <= 0) Die(); else EnterChase();
        }

        private void ApplyTypeValues()
        {
            switch (type)
            {
                case ZombieType.Schlurfer:
                    maxHealth = Mathf.Max(maxHealth, 100); agent.speed = 1.65f; agent.acceleration = 5f; break;
                case ZombieType.Renner:
                    maxHealth = Mathf.Max(maxHealth, 70); agent.speed = 4.9f; agent.acceleration = 18f;
                    sightDistance *= 1.15f; break;
                case ZombieType.Waechter:
                    maxHealth = Mathf.Max(maxHealth, 260); agent.speed = 2.2f; agent.acceleration = 7f;
                    damage = Mathf.Max(damage, 28); break;
            }
            agent.angularSpeed = type == ZombieType.Renner ? 720f : 280f;
            agent.stoppingDistance = attackDistance * 0.8f;
        }

        private bool CanSeeTarget()
        {
            Vector3 eye = transform.position + Vector3.up * 1.55f;
            Vector3 targetPoint = target.position + Vector3.up;
            Vector3 delta = targetPoint - eye;
            if (delta.sqrMagnitude > sightDistance * sightDistance) return false;
            if (Vector3.Angle(transform.forward, delta) > sightAngle * 0.5f) return false;
            return !Physics.Raycast(eye, delta.normalized, delta.magnitude, sightBlockingMask,
                QueryTriggerInteraction.Ignore);
        }

        private void OnNoise(NoiseEvent noise)
        {
            if (state == State.Dead || noise.Source == gameObject) return;
            float multiplier = type == ZombieType.Renner ? 1.75f : type == ZombieType.Waechter ? 1.2f : 0.8f;
            float range = noise.Radius * multiplier;
            if ((noise.Position - transform.position).sqrMagnitude > range * range) return;
            investigatePosition = noise.Position;
            state = State.Investigate;
            agent.isStopped = false;
            agent.SetDestination(investigatePosition);
        }

        private void EnterChase()
        {
            state = State.Chase;
            agent.isStopped = false;
            if (type == ZombieType.Waechter && !guardianAlarmUsed)
            {
                guardianAlarmUsed = true;
                NoiseSystem.Emit(transform.position, guardianAlarmRadius, gameObject);
            }
        }

        private void UpdatePatrol()
        {
            if (patrolPoints == null || patrolPoints.Length == 0) { state = State.Idle; return; }
            if (!agent.hasPath || agent.remainingDistance <= 0.35f)
            {
                agent.SetDestination(patrolPoints[patrolIndex].position);
                patrolIndex = (patrolIndex + 1) % patrolPoints.Length;
            }
        }

        private void UpdateInvestigate()
        {
            if (!agent.pathPending && agent.remainingDistance <= 0.6f)
                state = patrolPoints != null && patrolPoints.Length > 0 ? State.Patrol : State.Idle;
        }

        private void UpdateChase()
        {
            float sqrDistance = (target.position - transform.position).sqrMagnitude;
            if (sqrDistance <= attackDistance * attackDistance) { state = State.Attack; agent.isStopped = true; return; }
            agent.SetDestination(target.position);
        }

        private void UpdateAttack()
        {
            Vector3 delta = target.position - transform.position;
            if (delta.sqrMagnitude > attackDistance * attackDistance * 1.35f) { EnterChase(); return; }
            if (Time.time < nextAttackTime) return;
            nextAttackTime = Time.time + attackCooldown;
            target.SendMessage("ReceiveDamage", damage, SendMessageOptions.DontRequireReceiver);
        }

        private void Die()
        {
            state = State.Dead;
            agent.isStopped = true;
            agent.enabled = false;
            enabled = false;
        }
    }
}
