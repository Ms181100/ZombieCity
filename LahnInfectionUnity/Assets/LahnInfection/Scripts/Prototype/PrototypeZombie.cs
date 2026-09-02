using UnityEngine;

namespace LahnInfection.Prototype
{
    public sealed class PrototypeZombie : MonoBehaviour
    {
        public enum Kind { Shambler, Runner, Guardian }
        private Transform target;
        private PrototypeBootstrap game;
        private int health;
        private float speed;
        private float nextAttack;
        public Kind ZombieKind { get; private set; }

        public void Configure(Kind kind, Transform player, PrototypeBootstrap owner)
        {
            ZombieKind = kind; target = player; game = owner;
            health = kind == Kind.Guardian ? 230 : kind == Kind.Runner ? 70 : 100;
            speed = kind == Kind.Runner ? 4.4f : kind == Kind.Guardian ? 1.8f : 1.25f;
        }

        private void Update()
        {
            if (target == null) return;
            Vector3 delta = target.position - transform.position; delta.y = 0;
            if (delta.sqrMagnitude > 576f) return;
            if (delta.sqrMagnitude > 2.9f)
            {
                transform.position += delta.normalized * speed * Time.deltaTime;
                transform.rotation = Quaternion.Slerp(transform.rotation, Quaternion.LookRotation(delta), 8 * Time.deltaTime);
            }
            else if (Time.time >= nextAttack)
            {
                nextAttack = Time.time + 1.1f;
                game.HurtPlayer(ZombieKind == Kind.Guardian ? 24 : ZombieKind == Kind.Runner ? 16 : 10);
            }
        }

        public void Hit(int damage)
        {
            health -= damage;
            if (health > 0) return;
            game.ZombieDefeated(this);
            Destroy(gameObject);
        }
    }
}
