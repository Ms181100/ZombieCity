using UnityEngine;

namespace LahnInfection.Missions
{
    [RequireComponent(typeof(Collider))]
    public sealed class MissionTrigger : MonoBehaviour
    {
        [SerializeField] private LastSignalMission mission;
        [SerializeField] private string eventId;
        [SerializeField] private bool oneShot = true;
        private bool triggered;

        private void Reset() => GetComponent<Collider>().isTrigger = true;

        private void OnTriggerEnter(Collider other)
        {
            if ((oneShot && triggered) || !other.CompareTag("Player") || mission == null) return;
            triggered = mission.TryAdvance(eventId);
        }
    }
}
