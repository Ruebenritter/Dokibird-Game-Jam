using Game.code_core.enums;
using Godot;
using System;

public class DistanceComponent : Node2D
{
    [Export]
    public DistanceLevel DistanceLevel;

    // Called when the node enters the scene tree for the first time.
    public override void _Ready()
    {
        // float scale = distanceLevel switch
        // getParentNode.scale = DistanceLevel switch
    }

    //  // Called every frame. 'delta' is the elapsed time since the previous frame.
    //  public override void _Process(float delta)
    //  {
    //      
    //  }
}
