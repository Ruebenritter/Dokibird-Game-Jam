using Godot;
using System;

public partial class GameViewModel : Control
{
    [Export]
    public NodePath BackgroundNodePath;
    [Export]
    public NodePath AmmoDisplayPath;
    [Export]
    public NodePath CameraPath;
    [Export]
    public PackedScene AmmoIconScene;
    [Export]
    int ScrollSpeed = 300;
    [Export]
    int ScrollEdgeThreshold = 50;
    [Export]
    public NodePath TimerLabelPath;
    [Export]
    public NodePath TimerPath;
    [Export]
    public PackedScene CrosshairScene;
    
    // Declare member variables here. Examples:
    private Vector2 _viewPortSize;
    private Node2D _backgroundNode;
    private Camera2D _camera;
    private float _minXPosition;
    private float _maxXPosition;

    // Shooting
    private HBoxContainer _ammoDisplay;
    private const int MAX_AMMO_COUNT = 5;
    private const float RELOAD_TIME = 3.0f; // Time in seconds to reload
    private bool _isReloading = false;
    private int _currentReloadedShells = 0;
    private Dart _lastDart;

    // Countdown
    private Label _timerLabel;
    private int _remainingSeconds = 90; // Countdown time in seconds
    private Timer _countdownTimer;

    private AnimatedSprite2D _crosshairSprite;

    // Called when the node enters the scene tree for the first time.
    public override void _Ready()
    {

        _viewPortSize = GetViewport().GetVisibleRect().Size;
        GD.Print("SubViewport size: ", _viewPortSize.x, "x", _viewPortSize.y);

        _camera = GetNode<Camera2D>(CameraPath);
        if (_camera == null)
        {
            GD.PrintErr("Camera2D node not found at path: ", CameraPath);
            return;
        }

        // Place camera at the center of the viewport
        _camera.Position = new Vector2(0, _viewPortSize.y / 2);

        _crosshairSprite = CrosshairScene.Instance<AnimatedSprite2D>();

        _backgroundNode = GetNode<Node2D>(BackgroundNodePath);
        _backgroundNode.Position = new Vector2(0, _viewPortSize.y);
        var textureWidth = _backgroundNode.GetNode<TextureRect>("TextureRect").Texture2D.GetWidth();

        _minXPosition = -textureWidth / 2 + _viewPortSize.x / 2;
        _maxXPosition = textureWidth / 2 - (_viewPortSize.x / 2);


        //// Print initial positions and limits for debugging
        //GD.Print("Background initial position: ", _backgroundNode.Position);
        //GD.Print("Camera initial position: ", _camera.Position);
        //GD.Print("Min X Position: ", _minXPosition);
        //GD.Print("Max X Position: ", _maxXPosition);

        _ammoDisplay = GetNode<HBoxContainer>(AmmoDisplayPath);
        for (int i = 0; i < MAX_AMMO_COUNT; i++)
        {
           _ammoDisplay.AddChild(AmmoIconScene.Instance());
        }

        // Countdown Timer
        _timerLabel = GetNode<Label>(TimerLabelPath);
        _countdownTimer = GetNode<Timer>(TimerPath);

        _countdownTimer.WaitTime = 1.0f; 
        _countdownTimer.OneShot = false; 
        _countdownTimer.Start();

        _countdownTimer.Connect("timeout", new Callable(this, nameof(OnTimerTick)));

    }

    public override void _Input(InputEvent @event)
    {
        if (@event is InputEventMouseButton mouseEvent && mouseEvent.Pressed)
        {
            if (mouseEvent.ButtonIndex == (int)ButtonList.Right && !_isReloading)
            {
                _isReloading = true;
                _currentReloadedShells = 0;

                // Clear old shells
                foreach (Control child in _ammoDisplay.GetChildren())
                {
                    _ammoDisplay.RemoveChild(child);
                    child.QueueFree();
                }

                GD.Print("Reloading...");
                ReloadNextShell(); // Start first shell immediately
            }

            if (mouseEvent.ButtonIndex == (int)ButtonList.Left)
            {
                if (_isReloading)
                {
                    GD.Print("Cannot shoot while reloading!");
                    return;
                }

                var childCount = _ammoDisplay.GetChildCount();
                if (childCount > 0)
                {
                    GD.Print("Shooting!");
                    var ammoIcon = _ammoDisplay.GetChild(0) as Control;
                    _ammoDisplay.RemoveChild(ammoIcon);
                    ammoIcon.QueueFree();
                }
            }
        }

// Make crosshair follow cursor
if (@event is InputEventMouseMotion mouseMotionEvent)
        {
            _crosshairSprite.Position = mouseMotionEvent.Position;
        }
    }

    private void ReloadNextShell()
    {
        _lastDart?.StopBlinking(); // Stop blinking on the last dart if it exists

        if (_currentReloadedShells >= MAX_AMMO_COUNT)
        {
            _isReloading = false;
            _lastDart = null; // Clear the last dart reference
            GD.Print("Reload complete.");
            return;
        }

        var icon = AmmoIconScene.Instance<Control>();
        _ammoDisplay.AddChild(icon);
        if (icon is Dart dart)
        {
            _lastDart = dart;
            dart.Blink();
        }

        _currentReloadedShells++;

        // Schedule next shell
        var shellInterval = RELOAD_TIME / MAX_AMMO_COUNT;
        GetTree().CreateTimer(shellInterval).Connect("timeout", new Callable(this, nameof(ReloadNextShell)));
    }


    //  // Called every frame. 'delta' is the elapsed time since the previous frame.
    public override void _Process(float delta)
    {
        Vector2 mousePosition = GetViewport().GetMousePosition();

        
            if (mousePosition.x <= ScrollEdgeThreshold)
                ScrollLeft(delta);
            else if (mousePosition.x >= _viewPortSize.x - ScrollEdgeThreshold)
                ScrollRight(delta);
        
    }

    private void ScrollRight(float delta)
    {
        float newX = Mathf.Clamp(_camera.Position.x + ScrollSpeed * delta, _minXPosition, _maxXPosition);
        _camera.Position = new Vector2(newX, _camera.Position.y);
    }

    private void ScrollLeft(float delta)
    {
        float newX = Mathf.Clamp(_camera.Position.x - ScrollSpeed * delta, _minXPosition, _maxXPosition);
        _camera.Position = new Vector2(newX, _camera.Position.y);
    }

    #region Countdown Timer
    private void OnTimerTick()
    {
        _remainingSeconds--;

        if (_remainingSeconds <= 0)
        {
            _countdownTimer.Stop();
            _timerLabel.Text = "FIN";
            GD.Print("Time's up!");
            // Optionally trigger game end here
            return;
        }

        _timerLabel.Text = FormatTime(_remainingSeconds);
    }

    private string FormatTime(int totalSeconds)
    {
        int minutes = totalSeconds / 60;
        int seconds = totalSeconds % 60;
        return $"{minutes:D2}:{seconds:D2}";
    }
    #endregion

}
