using System;
using UnityEngine;

namespace LahnInfection.Missions
{
    public sealed class LastSignalMission : MonoBehaviour
    {
        public enum Stage
        {
            WakeInCellar,
            LearnMovement,
            TakePipeWrench,
            CrossB49Silently,
            SearchPharmacy,
            DefeatRunner,
            ReachFireStation,
            HandleGuardian,
            StartGenerator,
            SendRadioSignal,
            Completed
        }

        [SerializeField] private Stage currentStage = Stage.WakeInCellar;
        [SerializeField] private string[] objectiveTexts =
        {
            "Steh auf und sieh dich im Keller um.",
            "Bewege dich und lerne die Steuerung.",
            "Nimm die Rohrzange von der Werkbank.",
            "Überquere die B49, ohne die Schlurfer anzulocken.",
            "Durchsuche die Apotheke nach einem Medikit.",
            "Besiege den Renner und verlasse die Apotheke.",
            "Erreiche die Feuerwehrwache.",
            "Lenke den Wächter ab oder besiege ihn.",
            "Starte den Notstromgenerator.",
            "Setze an der Funkanlage einen Notruf ab.",
            "Das letzte Signal wurde gesendet."
        };

        public Stage CurrentStage => currentStage;
        public string CurrentObjective => objectiveTexts[Mathf.Clamp((int)currentStage, 0, objectiveTexts.Length - 1)];
        public event Action<Stage, string> StageChanged;
        public event Action MissionCompleted;

        private void Start() => NotifyStage();

        public bool TryAdvance(string eventId)
        {
            bool valid = currentStage switch
            {
                Stage.WakeInCellar => eventId == "player_awake",
                Stage.LearnMovement => eventId == "movement_complete",
                Stage.TakePipeWrench => eventId == "pipe_wrench_taken",
                Stage.CrossB49Silently => eventId == "b49_crossed",
                Stage.SearchPharmacy => eventId == "medikit_looted",
                Stage.DefeatRunner => eventId == "runner_defeated",
                Stage.ReachFireStation => eventId == "fire_station_reached",
                Stage.HandleGuardian => eventId == "guardian_resolved",
                Stage.StartGenerator => eventId == "generator_started",
                Stage.SendRadioSignal => eventId == "radio_signal_sent",
                _ => false
            };
            if (!valid) return false;
            currentStage = (Stage)((int)currentStage + 1);
            NotifyStage();
            if (currentStage == Stage.Completed) MissionCompleted?.Invoke();
            return true;
        }

        public void RestoreStage(int stageIndex)
        {
            currentStage = (Stage)Mathf.Clamp(stageIndex, 0, (int)Stage.Completed);
            NotifyStage();
        }

        private void NotifyStage() => StageChanged?.Invoke(currentStage, CurrentObjective);
    }
}
