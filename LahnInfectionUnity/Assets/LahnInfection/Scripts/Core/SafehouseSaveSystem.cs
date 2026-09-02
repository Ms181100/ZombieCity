using System;
using System.IO;
using LahnInfection.Missions;
using UnityEngine;

namespace LahnInfection.Core
{
    public sealed class SafehouseSaveSystem : MonoBehaviour
    {
        [Serializable]
        private sealed class SaveData
        {
            public float x;
            public float y;
            public float z;
            public int missionStage;
            public long savedAtUtc;
        }

        private string SavePath => Path.Combine(Application.persistentDataPath, "lahn_infection_save.json");
        public bool HasSave => File.Exists(SavePath);

        public void Save(Transform player, LastSignalMission mission)
        {
            if (player == null || mission == null) return;
            SaveData data = new SaveData
            {
                x = player.position.x,
                y = player.position.y,
                z = player.position.z,
                missionStage = (int)mission.CurrentStage,
                savedAtUtc = DateTimeOffset.UtcNow.ToUnixTimeSeconds()
            };
            string temporary = SavePath + ".tmp";
            File.WriteAllText(temporary, JsonUtility.ToJson(data, true));
            if (File.Exists(SavePath)) File.Delete(SavePath);
            File.Move(temporary, SavePath);
        }

        public bool Load(Transform player, LastSignalMission mission)
        {
            if (!HasSave || player == null || mission == null) return false;
            try
            {
                SaveData data = JsonUtility.FromJson<SaveData>(File.ReadAllText(SavePath));
                player.position = new Vector3(data.x, data.y, data.z);
                mission.RestoreStage(data.missionStage);
                return true;
            }
            catch (Exception exception)
            {
                Debug.LogError($"Spielstand konnte nicht geladen werden: {exception.Message}");
                return false;
            }
        }
    }
}
