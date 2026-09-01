using System;
using UnityEngine;

namespace LahnInfection.Player
{
    public sealed class PlayerHealthStatus : MonoBehaviour
    {
        [SerializeField] private int maximumHealth = 100;
        [SerializeField] private float infectionPerSecondUntreated = 0.12f;
        public int Health { get; private set; }
        public float Infection { get; private set; }
        public bool Bleeding { get; private set; }
        public bool Fractured { get; private set; }
        public float MovementMultiplier => Fractured ? 0.5f : 1f;
        public event Action Changed;
        public event Action Died;
        private float bleedingDamageAccumulator;

        private void Awake() => Health = maximumHealth;

        private void Update()
        {
            if (Bleeding)
            {
                bleedingDamageAccumulator += 2f * Time.deltaTime;
                if (bleedingDamageAccumulator >= 1f)
                {
                    int damage = Mathf.FloorToInt(bleedingDamageAccumulator);
                    bleedingDamageAccumulator -= damage;
                    ReceiveDamage(damage);
                }
            }
            if (Infection > 0f && Infection < 100f)
            {
                Infection = Mathf.Min(100f, Infection + infectionPerSecondUntreated * Time.deltaTime);
                Changed?.Invoke();
            }
        }

        public void ReceiveDamage(int amount)
        {
            if (Health <= 0) return;
            Health = Mathf.Max(0, Health - Mathf.Max(0, amount));
            Changed?.Invoke();
            if (Health == 0) Died?.Invoke();
        }

        public void AddWound(bool bleeding, bool fracture, float infection)
        {
            Bleeding |= bleeding;
            Fractured |= fracture;
            Infection = Mathf.Clamp(Infection + infection, 0f, 100f);
            Changed?.Invoke();
        }

        public void UseBandage() { Bleeding = false; bleedingDamageAccumulator = 0f; Health = Mathf.Min(maximumHealth, Health + 15); Changed?.Invoke(); }
        public void UseSplint() { Fractured = false; Changed?.Invoke(); }
        public void UseAntibiotics() { Infection = Mathf.Max(0f, Infection - 30f); Changed?.Invoke(); }
    }
}
