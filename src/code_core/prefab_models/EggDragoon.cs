using Game.code_core.enums;
using Godot;
using System;

public class EggDragoon : Node2D
{
    [Export]
    public NodePath DragoonTexturePath;
    [Export]
    public NodePath HeadHitboxPath;
    [Export]
    public NodePath BodyHitboxPath;
    [Export]
    public DragoonType DragoonType;
    // Declare member variables here. Examples:
    // private int a = 2;
    // private string b = "text";
    private Area2D _headHitbox;
    private Area2D _bodyHitbox;
    private TextureRect _dragoonTexture;
    private DragoonType _dragoonType;

    // Called when the node enters the scene tree for the first time.
    public override void _Ready()
    {
        _headHitbox = GetNode<Area2D>(HeadHitboxPath);
        _bodyHitbox = GetNode<Area2D>(BodyHitboxPath);
        _dragoonTexture = GetNode<TextureRect>(DragoonTexturePath);

        _headHitbox.Connect("input_event", this, nameof(OnHeadHitboxInput));
    }

    //  // Called every frame. 'delta' is the elapsed time since the previous frame.
    //  public override void _Process(float delta)
    //  {
    //      
    //  }
    public void OnHeadHitboxInput(Node viewport, InputEvent @event, int shapeIdx)
    {
        if (@event is InputEventMouseButton mouseEvent &&
            mouseEvent.Pressed &&
            mouseEvent.ButtonIndex == (int)ButtonList.Left)
        {
            GD.Print("Headshot registered!");
            // your logic here
        }
    }

}
