using System.Collections.Generic;
using LahnInfection.Missions;
using UnityEngine;

namespace LahnInfection.Prototype
{
    public sealed class PrototypeBootstrap : MonoBehaviour
    {
        private readonly List<PrototypeZombie> zombies = new(16);
        private CharacterController player;
        private Camera view;
        private LastSignalMission mission;
        private AudioSource speaker;
        private Vector2 move;
        private Vector2 look;
        private Vector2 stickOrigin;
        private int moveFinger = -1;
        private int lookFinger = -1;
        private float yaw;
        private float pitch = 12f;
        private int health = 100;
        private int ammo = 12;
        private int reserve = 48;
        private int score;

        [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.AfterSceneLoad)]
        private static void StartGame()
        {
            if (FindFirstObjectByType<PrototypeBootstrap>() == null)
                new GameObject("Lahn-Infection").AddComponent<PrototypeBootstrap>();
        }

        private void Awake()
        {
            Application.targetFrameRate = 60;
            Screen.sleepTimeout = SleepTimeout.NeverSleep;
            BuildWorld();
            BuildPlayer();
            mission = gameObject.AddComponent<LastSignalMission>();
            mission.TryAdvance("player_awake");
            SpawnZombies();
        }

        private void BuildWorld()
        {
            RenderSettings.ambientLight = new Color(0.14f, 0.17f, 0.22f);
            RenderSettings.fog = true;
            RenderSettings.fogColor = new Color(0.025f, 0.04f, 0.055f);
            RenderSettings.fogDensity = 0.013f;
            Light moon = new GameObject("Mondlicht").AddComponent<Light>();
            moon.type = LightType.Directional;
            moon.color = new Color(0.58f, 0.68f, 0.86f);
            moon.intensity = 1.15f;
            moon.transform.rotation = Quaternion.Euler(42f, -25f, 0f);
            Block("B49", new(0f, -0.25f, 42f), new(13f, .5f, 105f), new(.07f, .075f, .08f));
            for (int i = -4; i <= 5; i++) Block("Markierung", new(0f, .02f, i * 11f + 42f), new(.16f, .03f, 5f), new(.8f, .76f, .58f));
            for (int side = -1; side <= 1; side += 2)
            {
                Block("Gehweg", new(side * 8f, 0f, 42f), new(3f, .3f, 105f), new(.25f, .26f, .27f));
                for (int i = 0; i < 9; i++)
                {
                    float h = 7f + i % 3 * 1.6f;
                    Block("Fachwerkhaus", new(side * 12f, h * .5f, i * 12f - 8f), new(5f, h, 10f), i % 2 == 0 ? new(.25f, .18f, .14f) : new(.31f, .28f, .23f));
                }
            }
            Block("APOTHEKE", new(-11f, 2.5f, 34f), new(5f, 5f, 10f), new(.22f, .36f, .25f));
            Block("FEUERWEHR", new(11f, 3f, 80f), new(6f, 6f, 13f), new(.38f, .1f, .08f));
        }

        private void BuildPlayer()
        {
            GameObject root = new("Spieler");
            root.transform.position = new(0f, 1.1f, -6f);
            player = root.AddComponent<CharacterController>();
            player.height = 1.8f;
            player.radius = .42f;
            view = new GameObject("Kamera").AddComponent<Camera>();
            view.transform.SetParent(root.transform, false);
            view.transform.localPosition = new(0f, 2.25f, -4.2f);
            view.fieldOfView = 64f;
            speaker = root.AddComponent<AudioSource>();
        }

        private void SpawnZombies()
        {
            for (int i = 0; i < 12; i++)
            {
                PrototypeZombie.Kind kind = i == 7 ? PrototypeZombie.Kind.Runner : i == 11 ? PrototypeZombie.Kind.Guardian : PrototypeZombie.Kind.Shambler;
                GameObject body = GameObject.CreatePrimitive(PrimitiveType.Capsule);
                body.name = kind.ToString();
                body.transform.position = new((i % 2 == 0 ? -1f : 1f) * (2f + i % 3), 1f, 13f + i * 6f);
                body.transform.localScale = kind == PrototypeZombie.Kind.Guardian ? new(1.25f, 1.3f, 1.25f) : Vector3.one;
                body.GetComponent<Renderer>().material.color = kind == PrototypeZombie.Kind.Runner ? new(.52f, .14f, .1f) : kind == PrototypeZombie.Kind.Guardian ? new(.1f, .14f, .22f) : new(.12f, .3f, .16f);
                PrototypeZombie zombie = body.AddComponent<PrototypeZombie>();
                zombie.Configure(kind, player.transform, this);
                zombies.Add(zombie);
            }
        }

        private void Update()
        {
            ReadTouches();
            Vector3 direction = player.transform.right * move.x + player.transform.forward * move.y;
            direction.y = -1.5f;
            player.Move(direction * (move.magnitude > .9f ? 5.4f : 3.2f) * Time.deltaTime);
            yaw += look.x * .13f;
            pitch = Mathf.Clamp(pitch - look.y * .1f, -25f, 55f);
            player.transform.rotation = Quaternion.Euler(0f, yaw, 0f);
            view.transform.localRotation = Quaternion.Euler(pitch, 0f, 0f);
        }

        private void ReadTouches()
        {
            move = look = Vector2.zero;
            for (int i = 0; i < Input.touchCount; i++)
            {
                Touch t = Input.GetTouch(i);
                if (t.phase == TouchPhase.Began)
                {
                    if (t.position.x < Screen.width * .48f && moveFinger < 0) { moveFinger = t.fingerId; stickOrigin = t.position; }
                    else if (lookFinger < 0) lookFinger = t.fingerId;
                }
                if (t.fingerId == moveFinger)
                {
                    move = Vector2.ClampMagnitude((t.position - stickOrigin) / 90f, 1f);
                    if (t.phase is TouchPhase.Ended or TouchPhase.Canceled) moveFinger = -1;
                }
                else if (t.fingerId == lookFinger)
                {
                    look += t.deltaPosition;
                    if (t.phase is TouchPhase.Ended or TouchPhase.Canceled) lookFinger = -1;
                }
            }
        }

        private void Fire()
        {
            if (ammo < 1) { Tone(130, .07f, .1f); return; }
            ammo--;
            Tone(90, .09f, .42f);
            Ray ray = view.ViewportPointToRay(new(.5f, .5f));
            if (Physics.Raycast(ray, out RaycastHit hit, 45f) && hit.collider.TryGetComponent(out PrototypeZombie zombie)) zombie.Hit(45);
        }

        private void Reload()
        {
            int loaded = Mathf.Min(12 - ammo, reserve);
            ammo += loaded;
            reserve -= loaded;
            Tone(220, .12f, .16f);
        }

        public void ZombieDefeated(PrototypeZombie zombie)
        {
            score += zombie.ZombieKind == PrototypeZombie.Kind.Guardian ? 300 : zombie.ZombieKind == PrototypeZombie.Kind.Runner ? 175 : 100;
            zombies.Remove(zombie);
        }

        public void HurtPlayer(int damage)
        {
            health = Mathf.Max(0, health - damage);
            Tone(55, .14f, .2f);
            if (health == 0) { player.transform.position = new(0f, 1.1f, -6f); health = 100; }
        }

        private void Tone(float hz, float seconds, float volume)
        {
            int count = Mathf.CeilToInt(44100 * seconds);
            AudioClip clip = AudioClip.Create("SFX", count, 1, 44100, false);
            float[] samples = new float[count];
            for (int i = 0; i < count; i++) samples[i] = Mathf.Sin(2 * Mathf.PI * hz * i / 44100) * volume * (1 - i / (float)count);
            clip.SetData(samples, 0);
            speaker.PlayOneShot(clip);
            Destroy(clip, seconds + .2f);
        }

        private void OnGUI()
        {
            GUI.Label(new(18, 14, Screen.width - 36, 30), $"LEBEN {health}    MUNITION {ammo}/{reserve}    PUNKTE {score}");
            GUI.Label(new(18, 43, Screen.width - 36, 45), "MISSION: " + mission.CurrentObjective);
            float s = Mathf.Max(72, Screen.height * .12f);
            if (GUI.Button(new(Screen.width - s - 22, Screen.height - s - 22, s, s), "FEUER")) Fire();
            if (GUI.Button(new(Screen.width - s * 2 - 38, Screen.height - s * .75f - 22, s * .85f, s * .7f), "LADEN")) Reload();
            GUI.Box(new(Screen.width * .5f - 1, Screen.height * .5f - 9, 2, 18), GUIContent.none);
            GUI.Box(new(Screen.width * .5f - 9, Screen.height * .5f - 1, 18, 2), GUIContent.none);
        }

        private static void Block(string name, Vector3 position, Vector3 scale, Color color)
        {
            GameObject block = GameObject.CreatePrimitive(PrimitiveType.Cube);
            block.name = name;
            block.transform.position = position;
            block.transform.localScale = scale;
            block.GetComponent<Renderer>().material.color = color;
        }
    }
}
