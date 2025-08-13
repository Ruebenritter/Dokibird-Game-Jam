using Godot;
using System;

public partial class Dart : PanelContainer
{
    // Declare member variables here. Examples:
    // private int a = 2;
    // private string b = "text";
    private Timer _blinkTimer;
    private bool _isBlinking = false;

    // Called when the node enters the scene tree for the first time.
    public override void _Ready()
    {
        _blinkTimer = new Timer
        {
            WaitTime = 0.2f,
            OneShot = false,
            Autostart = false
        };

        AddChild(_blinkTimer);
        _blinkTimer.Connect("timeout", new Callable(this, nameof(OnBlinkTimerTimeout)));
    }

    private void OnBlinkTimerTimeout()
    {
       Visible = !Visible; // Toggle visibility
    }

    //  // Called every frame. 'delta' is the elapsed time since the previous frame.
    //  public override void _Process(float delta)
    //  {
    //      
    //  }

    public void Blink()
    {
        if (_isBlinking) return;

        _isBlinking = true;
        _blinkTimer.Start();
    }

    public void StopBlinking()
    {
        _blinkTimer.Stop();
        Visible = true; // Ensure visibility is reset
        _isBlinking = false;
    }
}
