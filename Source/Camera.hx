package  ;

import core.Element;
import core.AnimatedSprite;
import openfl.display.Bitmap;
import openfl.display.Shape;
import openfl.events.Event;
import openfl.geom.Point;
import openfl.geom.Rectangle;

/**
 * ...
 * @author Chambers
 */
class Camera extends Element {
	
	public var id:Int;
	
	private var _anim:AnimatedSprite;
    private var _light:Bitmap;
	
	public static var BLUE:String = "blue";
    public static var GREEN:String = "green";
    public static var RED:String = "red";
	
	private var FRAME_WIDTH:Int = 60;
    private var FRAME_HEIGHT:Int = 60;
	
	public var initialAngle:Float;
	public var angle:Float = 0;
	public var deltaMax:Float = 0.3;
	public var ANGULAR_SPEED:Float = 0.5;
	public var animPos:Float = 0;
	public var goingBack:Bool;
	public var waitTimer:Float;
	public var attentionTimer:Float = 0;
	
	public var eye:Point;
	
	public function new(x:Float, y:Float, color:String, id:Int) {
        this.id = id;
		super ();
		
		this.x = x;
		this.y = y;
		
		eye = new Point();
		initialAngle = 1;
		angle = 1;
		goingBack = false;
		
		_anim = new AnimatedSprite("assets/animations.json", "camera") ;

		eye.x = x + 30;
		eye.y = y + 40 * 2 + 3;
		addElement(_anim);
	}
	
	override public function update(dt:Float):Void 
    {
        super.update(dt);
		
		if (waitTimer > 0) {
			waitTimer -= dt;
		}
        else {
            if (goingBack) {
                angle += dt * ANGULAR_SPEED;
                if (angle > initialAngle + deltaMax) {
                    angle = initialAngle + deltaMax;
                    goingBack = false;
                    waitTimer = 1;
                }
            }
            else { angle -= dt * ANGULAR_SPEED;
                if (angle < initialAngle - deltaMax) {
                    angle = initialAngle - deltaMax;
                    goingBack = true;
                    waitTimer = 1;
                }
            }
        }

        animPos = Math.abs(Math.floor((angle - 0.7) / (2 * deltaMax) * 6.99) - 6);
        _anim.setAnimation("a" + animPos);
    }

    override public function draw():Void 
    {
        super.draw();

        #if debug
        graphics.clear();
        graphics.beginFill(0xFF0000);
        graphics.drawCircle(eye.x - x, eye.y - y, 5);
        graphics.endFill();
        graphics.lineStyle(1, 0x00FF00);
        graphics.moveTo(eye.x - x, eye.y - y);
        graphics.lineTo(eye.x - x + 300 * Math.cos(angle * Math.PI / 2),
                            eye.y - y + 300 * Math.sin(angle * Math.PI / 2));
        graphics.moveTo(eye.x - x, eye.y - y);
        graphics.lineTo(
                eye.x - x + 300 * Math.cos(angle * Math.PI / 2 - Math.PI / 4),
                eye.y - y + 300 * Math.sin(angle * Math.PI / 2 - Math.PI / 4));
        graphics.moveTo(eye.x - x, eye.y - y);
        graphics.lineTo(
                eye.x - x + 300 * Math.cos(angle * Math.PI / 2 + Math.PI / 4),
                eye.y - y + 300 * Math.sin(angle * Math.PI / 2 + Math.PI / 4));
        graphics.drawCircle(eye.x - x, eye.y - y, 300);
        #end
    }

    public function focusOnHero(p:Point):Void {

    }

    public function activate():Void {

    }

    public function deactivate():Void {

    }

	public function alert():Void 
    {
		
	}
}
