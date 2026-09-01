using System;
using UnityEngine;

namespace LahnInfection.Core
{
    public readonly struct NoiseEvent
    {
        public readonly Vector3 Position;
        public readonly float Radius;
        public readonly GameObject Source;

        public NoiseEvent(Vector3 position, float radius, GameObject source)
        {
            Position = position;
            Radius = radius;
            Source = source;
        }
    }

    public static class NoiseSystem
    {
        public static event Action<NoiseEvent> Emitted;

        public static void Emit(Vector3 position, float radius, GameObject source = null)
        {
            Emitted?.Invoke(new NoiseEvent(position, Mathf.Max(0f, radius), source));
        }
    }
}
