#include "NuMenuCommon.as";
#include "NuTextCommon.as";

bool canSeeButtons(CBlob@ this, CBlob@ caller, bool team_only = false, f32 max_distance = 9999.0f)
{
	if ((this is null || caller is null)) { return false; }

    max_distance = this.getRadius() + caller.getRadius()//The radius of the blob plus the player's blob. (basically both their sizes)
    + max_distance;//Plus max_distance

    if ((team_only && caller.getTeamNum() != this.getTeamNum()) ||//return false if not equal to this team.
        this.getDistanceTo(caller) > max_distance) { return false; }//return false if the distance is further than distance_max.

    CInventory@ inv = this.getInventory();

	return (
		//is attached to this or not attached at all (applies to vehicles and quarters)
		(caller.isAttachedTo(this) || !caller.isAttached()) &&
		//is inside this inventory or not inside an inventory at all (applies to crates)
		((inv !is null && inv.isInInventory(caller)) || !caller.isInInventory())
	);
}

//Does all that is usually needed when creating a button.
NuMenu::MenuButton@ CreateButtonFull(CBlob@ owner, CBlob@ caller, string text, string icon_path, Vec2f icon_size, u16 default_frame, u16 hover_frame, u16 pressing_frame)
{
    NuMenu::MenuButton@ button = CreateButton(owner);

    setText(button, text);//The text on the button.

    //Icon
    addIcon(button,//Button.
        icon_path,//Image name
        icon_size,//Icon frame size
        default_frame,//Default frame
        hover_frame,//Hover frame 
        pressing_frame//Pressing frame
    );

    addButton(caller, button);

    return @button;
}

//Command id
NuMenu::MenuButton@ CreateButtonFull(CBlob@ owner, CBlob@ caller, string text, string icon_path, Vec2f icon_size, u16 default_frame, u16 hover_frame, u16 pressing_frame, u8 command_id, CBitStream params = CBitStream())
{
    NuMenu::MenuButton@ button = CreateButtonFull(owner, caller, text, icon_path, icon_size, default_frame, hover_frame, pressing_frame);

    button.setCommandID(command_id);
    if(params.Length() != 0)
    {
        button.params = params;    
    }
    return @button;
}
//Command string
NuMenu::MenuButton@ CreateButtonFull(CBlob@ owner, CBlob@ caller, string text, string icon_path, Vec2f icon_size, u16 default_frame, u16 hover_frame, u16 pressing_frame, string command_string, CBitStream params = CBitStream())
{
    NuMenu::MenuButton@ button = CreateButtonFull(owner, caller, text, icon_path, icon_size, default_frame, hover_frame, pressing_frame);
    button.setCommandID(command_string);
    if(params.Length() != 0)
    {
        button.params = params;    
    }
    return @button;
}
//Function
NuMenu::MenuButton@ CreateButtonFull(CBlob@ owner, CBlob@ caller, string text, string icon_path, Vec2f icon_size, u16 default_frame, u16 hover_frame, u16 pressing_frame, NuMenu::RELEASE_CALLBACK@ func, CBitStream params = CBitStream())
{
    NuMenu::MenuButton@ button = CreateButtonFull(owner, caller, text, icon_path, icon_size, default_frame, hover_frame, pressing_frame);
    button.addReleaseListener(@func);
    if(params.Length() != 0)
    {
        button.params = params;    
    }
    return @button;
}

NuMenu::MenuButton@ CreateButton(CBlob@ this)
{
    NuMenu::MenuButton@ button = NuMenu::MenuButton("", this);//Name of the button, and the button's owner. The button will automatically follow the owner unless specified not to.

    //Debug
    //button.setSize(Vec2f(30,30));//Note as the start of a menu is the top left, unless compensated by setRelationPos, this will uncenter the button from the thing it's on.
    //button.setOffset(-(button.getSize() / 2));//Where the button is in relation to it's OwnerBlob. This should center the button directly on the blob.
    //button.setInterpolated(false);

    //MISC
    button.setRenderBackground(false);//Just in case this tries to render, stop it.
    button.kill_on_release = true;//Changes whether the button will be removed when it is pressed.(released) (logic for this happens outside the button class).
    button.die_when_no_owner = true;//Kills the button if the owner blob is gone.
    button.instant_press = true;//Button command/script is sent/called upon just pressing.
    button.enableRadius = 36.0f;//How close you have to be to press the button. Out of this distance the button is greyed out and unpressable.

    //Position
    button.setIsWorldPos(true);//This button is on the world.

    //Collision
    button.setRadius(8.0f);//Radius of button. The collision circle of the button.
    button.setCollisionLowerRight(Vec2f(0,0));//Removes the collision box. In most cases.
    button.setCollisionSetter(false);//By default, the button uses a collision box for collisions, not a radius. After changing the collision box, this will prevent the button from changing the collision box back to it's own size again.

    //Keys
    button.clearKeyCodes();//Clears default key codes used to press the button
    button.addKeyCode(KEY_LBUTTON);//The left mouse button can press a button

    //Text
    button.draw_text = false;//Don't initially draw text.
    //button.reposition_text = false;//Make sure the text is constantly under the button in the correct position when drawing.//Not required.
    button.default_buffer = 10.0f;//Buffer between bottom of the button and the text. Provided there is text.

    //Sound
    button.menu_sounds_on[NuMenu::JustHover] = "select.ogg";//Button sound played upon just hovering over the button.
    button.menu_sounds_on[NuMenu::Released] = "buttonclick.ogg";//Button sound played upon releasing the button.
    button.menu_volume = 3.0f;//Volume of sound from this button.
    button.play_sound_on_world = false;//This changes whether the sound is 2d or the sound is played on a point in the world.

    //Icon
    Nu::NuStateImage@ icon = button.setImage("GUI/InteractionIconsBackground.png",//Image name
        Vec2f(32, 32),//Icon frame size
        0,//Default frame
        1,//Hover frame 
        1,//Pressing frame
        0);//Image position
        
    Vec2f icon_offset;
    Nu::getPosOnSizeFull(Nu::POSCenter, button.getSize(), icon.getFrameSize(), icon_offset);
    icon.setOffset(icon_offset);

    icon.color_on[NuMenu::Disabled].setAlpha(80);//Get the color of the icon when it is disabled, and change it to fade out when disabled.


    return @button;
}

Nu::NuImage@ addIcon(NuMenu::MenuButton@ button, string icon_path, Vec2f icon_size, u16 default_frame, u16 hover_frame, u16 pressing_frame, u16 pos = 255)
{
    if(pos == 255)//No pos set?
    {
        for(u16 i = 0; i < 255; i++)//For every pos.
        {
            if(button.getImage(i) != null)//If this pos is set.
            {
                continue;//Next pos.
            }
            //Pos isn't set, this is an open pos.
            pos = i;//This is our pos.
            break;//Exit.
        }
    }

    //Icon
    Nu::NuStateImage@ icon = button.setImage(icon_path,//Image name
        icon_size,//Icon frame size
        default_frame,//Default frame
        hover_frame,//Hover frame 
        pressing_frame,//Pressing frame
        pos);//Image position

    Vec2f icon_offset;
    Nu::getPosOnSizeFull(Nu::POSCenter, button.getSize(), icon.getFrameSize(), icon_offset);
    icon.setOffset(icon_offset);

    icon.color_on[NuMenu::Disabled].setAlpha(80);//Get the color of the icon when it is disabled, and change it to fade out when disabled.

    return @icon;
}

void setText(NuMenu::MenuButton@ button, string _text, u8 pos = 255)
{
    if(pos == 255)
    {
        pos = Nu::POSUnder;
    }

    NuText@ text = button.setText(_text, "Calibri-48-Bold", pos);

    text.setScale(0.135f);//Scale of text.

    text.setColor(SColor(255, 255, 255, 255));//The color of the text of the button of the blob of the game of the computer of the screen

    button.RepositionText(button.getSize(), pos);
}

void addButton(CBlob@ caller, NuMenu::MenuButton@ button)
{
    //button.Tick(caller.getPosition());//Tick button once to initially set the button state. For example if the button is out of range this will instantly tell the button to be greyed. Without this the button with be normal for a tick.
    //button.setTicksSinceCreated(Nu::u32_max());

    array<NuMenu::MenuButton@>@ buttons;//Init array.
    getRules().get("NuButtons", @buttons);//Grab array.
    if(buttons == @null)
    {
        error("Tried to add button when NuButtons array was null.");
        return;
    }
    buttons.push_back(button);//Put button in CustomButtons array.
}