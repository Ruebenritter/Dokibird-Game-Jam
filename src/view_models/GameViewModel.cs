using Godot;
using System;

public class GameViewModel : Control
{
    [Export]
    public NodePath BackgroundNodePath { get; set; }
    [Export]
    public NodePath CameraPath;
    [Export]
    int ScrollSpeed = 300;
    [Export]
    int ScrollEdgeThreshold = 50;
    // Declare member variables here. Examples:
    private Vector2 _viewPortSize;
    private Node2D _backgroundNode;
    private Camera2D _camera;
    private float _minXPosition;
    private float _maxXPosition;

    // Called when the node enters the scene tree for the first time.
    public override void _Ready()
    {
        _viewPortSize = GetViewport().GetVisibleRect().Size;
        GD.Print("Viewport size: ", _viewPortSize.x, "x", _viewPortSize.y);

        _camera = GetNode<Camera2D>(CameraPath);
        if (_camera == null)
        {
            GD.PrintErr("Camera2D node not found at path: ", CameraPath);
            return;
        }

        // Place camera at the center of the viewport
        _camera.Position = new Vector2(0, _viewPortSize.y / 2);

        _backgroundNode = GetNode<Node2D>(BackgroundNodePath);
        _backgroundNode.Position = new Vector2(0, _viewPortSize.y);
        var textureWidth = _backgroundNode.GetNode<TextureRect>("TextureRect").Texture.GetWidth();

        _minXPosition = -textureWidth / 2 + _viewPortSize.x / 2;
        _maxXPosition = textureWidth / 2 - (_viewPortSize.x / 2);


        // Print initial positions and limits for debugging
        GD.Print("Background initial position: ", _backgroundNode.Position);
        GD.Print("Camera initial position: ", _camera.Position);
        GD.Print("Min X Position: ", _minXPosition);
        GD.Print("Max X Position: ", _maxXPosition);
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

}
