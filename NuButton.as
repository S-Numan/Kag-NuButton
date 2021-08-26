#include "NuMenuCommon.as";
#include "NuHub.as";

//TODO
//1. Figure out how to outline selected blobs better.
//2. Button appears behind things when you are also holding c to pick them up. Fix this. (remaking the rendering system would probably work).


u16 QUICK_PICK = 7;//Quickly tap e and let go before QUICK_PICK ticks pass to pick the closest button.
float QUICK_PICK_MAX_RANGE = 26.0f;

array<NuMenu::MenuButton@>@ buttons;
NuHub@ hub = @null;

bool init = false;
void onInit( CRules@ rules )
{
    if(!isClient())
    {
        return;
    }

    if(!rules.get("NuHub", @hub)) { error("Failed to get NuHub. Make sure NuToolsLogic is before anything else that tries to use NuHub."); return; }

    array<NuMenu::MenuButton@> _buttons = array<NuMenu::MenuButton@>();
    @buttons = @_buttons;

    //buttons.push_back(_menus[i]);
    //namehashes.push_back(_menus[i].getNameHash());

    rules.set("NuButtons", @buttons);   
    
    init = true;
}




u16 e_key_time = 0;
u16 e_key_time_old = e_key_time;

void onTick( CRules@ rules )
{
    if(!isClient())
    {
        return;
    }

    CPlayer@ player = getLocalPlayer();
    if(player == null)
    {
        buttons.clear();
        return;
    }
    CControls@ controls = getControls();
    if(controls == null)
    {
        buttons.clear();
        return;
    }



    CBlob@ blob = player.getBlob();
    
    bool e_key_release = false; 

    if(controls.isKeyPressed(KEY_KEY_E))
    {
        e_key_time_old = e_key_time;
        e_key_time++;
    }
    else if (e_key_time != 0)
    {
        e_key_time = 0;
        e_key_release = true;
    }
    else
    {
        e_key_time_old = 0;
    }



    u16 i;
    if(blob != null)
    {
        if(buttons.size() != 0)//Provided there is more than one button.
        {
            for(i = 0; i < buttons.size(); i++)//Tick buttons, then remove buttons if their owner_blobs are dead.
            {
                if(buttons[i] == null)
                {
                    error("how");
                    continue;
                }

                Vec2f blob_pos;
                Vec2f mouse_pos;
                if(buttons[i].isWorldPos())//World pos
                {
                    blob_pos = blob.getPosition();
                    mouse_pos = controls.getMouseWorldPos();
                }
                else//Screen pos
                {
                    blob_pos = blob.getScreenPos();
                    mouse_pos = controls.getMouseScreenPos();
                }
                
                if(e_key_release){ buttons[i].addKeyCode(KEY_KEY_E); buttons[i].initial_press = true;}
                buttons[i].Tick(mouse_pos, blob_pos);
                
                if(buttons.size() <= i || buttons[i] == @null)//If the button array or this button in specific somehow became null during the tick logic.
                {
                    continue;//restart the for loop after this point. The loop will automatically stop if the array is too small.
                }

                if(buttons[i].getKillMenu() && buttons[i].getOwnerBlob() == @null)
                {
                    buttons.removeAt(i);//Remove button
                    i--;//Go one button back
                    continue;//Next button
                }
                
                buttons[i].PostTick();
            }
        }

        for(i = 0; i < buttons.size(); i++)
        {
            
            if(buttons[i] == null)
            {
                error("how");
                continue;
            }

            //Text
            if(buttons[i].getMenuState() == NuMenu::Hover || buttons[i].getMenuState() == NuMenu::JustHover)
            {
                buttons[i].draw_text = true;
                
                CBlob@ owner_blob = @buttons[i].getOwnerBlob();
                
                if(owner_blob.getHealth() == 0.0f && owner_blob.getWidth() == 0.0f){ Nu::Error("Blob" + i + " is possibly fake null. It has a health of 0.0f and width of 0.0f. Set one of these two values on the blob"); continue; }//Can cause instant crashing if blob is destroyed, but not null because kag.

                CSprite@ owner_sprite = @owner_blob.getSprite();
                if(owner_sprite != @null)
                {
                    if(owner_sprite.getFrameWidth() == 0.0f || owner_sprite.getFrameHeight() == 0.0f) { Nu::Error("blob sprite width and/or height were 0."); continue; }
                    
                    CSpriteLayer@ outline = @owner_sprite.getSpriteLayer("outli");
                    if(outline == @null)//Outline not yet created (Happens once).
                    {
                        CSpriteLayer@ _outline = @owner_sprite.addSpriteLayer("outli", owner_sprite.getFilename(), owner_sprite.getFrameWidth(), owner_sprite.getFrameHeight(), owner_blob.getTeamNum(), 0);

                        _outline.setRenderStyle(RenderStyle::outline);
                        _outline.ScaleBy((owner_sprite.getFrameWidth() + 2.0f) / owner_sprite.getFrameWidth(), (owner_sprite.getFrameHeight() + 2.0f) / owner_sprite.getFrameHeight());
                        _outline.SetRelativeZ(-0.01f);
                        _outline.SetFrame(owner_sprite.getFrame());
                    }
                    else//Outline not null. (happens every tick after the first)
                    {
                        outline.SetFrame(owner_sprite.getFrame());
                    }
                }
            }
            else if(buttons[i].draw_text != false)
            {
                buttons[i].draw_text = false;
            
                CBlob@ owner_blob = buttons[i].getOwnerBlob();
                if(owner_blob != null)
                {
                    CSprite@ owner_sprite = owner_blob.getSprite();
                    if(owner_sprite != null)
                    {
                        if(owner_sprite.getSpriteLayer("outli") != null)
                        {
                            owner_sprite.RemoveSpriteLayer("outli");
                        }
                    }
                }
            }
            //Text

            if(buttons[i].getMenuState() == NuMenu::Released)
            {
                if(buttons[i].kill_on_release)
                {
                    if(e_key_release)
                    {
                        buttons.clear();
                        return;
                    }
                    buttons.removeAt(i);
                }
                break;
            }
        }

        //Quick pass through
        if(i == buttons.size()//If all buttons have been gone through and none of them released upon.
        && e_key_release && e_key_time_old < QUICK_PICK && buttons.size() > 0)
        {
            //Sort array 
            array<float> distances(buttons.size());

            i = 0;
            int j;
            int N = buttons.size();

            for(j = 0; j < N; j++)
            {
                distances[j] = Nu::getDistance(blob.getPosition(), buttons[j].getMiddle());
            }
            if(buttons.size() != 1)//No need to sort through a single button 
            {
                for (j=1; j<N; j++)
                {
                    for (i=j; i>0 && distances[i] < distances[i-1]; i--)
                    {
                        NuMenu::MenuButton@ _buttontemp;
                        float temporary;

                        temporary = distances [i];
                        @_buttontemp = @buttons[i];
                        distances [i] = distances [i - 1];
                        @buttons[i] = @buttons[i - 1];
                        distances [i - 1] = temporary;
                        @buttons[i - 1] = @_buttontemp;
                    }
                }
            }

            for(i = 0; i < buttons.size(); i++)
            {
                if (buttons[i].enableRadius == 0.0f || distances[i] < buttons[i].enableRadius)
                {
                    if(buttons[i].getButtonState() != NuMenu::Disabled && distances[i] < QUICK_PICK_MAX_RANGE)
                    {
                        buttons[i].setButtonState(NuMenu::Released);//Button pressed twice or something. - To future numan.
                        buttons[i].sendReleaseCommand(KEY_LBUTTON);
                        break;
                    }
                }
            }
            //Sort with the closest on the bottom of the array farthest at the top.
        }
        //Quick pass
    }
    else if(buttons.size() != 0)//Blob is equal to null.
    {
        buttons.clear();
    }


    if(e_key_release && buttons.size() != 0)//Tick after e key release
    {
        buttons.clear();
    }

    //Rendering
    for(u16 i = 0; i < buttons.size(); i++)
    {
        if(buttons[i] == null)
        {
            continue;
        }

        hub.RenderImage(buttons[i].getRenderLayer(), buttons[i].getRenderFunction(), buttons[i].isWorldPos());

    }
    //Rendering
}


void onRestart(CRules@ rules)
{
    onInit(rules);
}

void onReload( CRules@ rules )
{
    print("NuButton reloaded");
    onRestart(rules);
}
















//GetButtonsFor() example
/*

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (!canSeeButtons(this, caller,
    false,//Team only
    16.0f))//Max distance
    {
        return;
    }

    CBitStream params;
	params.write_u16(caller.getNetworkID());

	//Sets up things easily.
    CreateButtonFull(this,//The blob this button will follow. 
        caller,//The player blob.
        getTranslatedString("Activate"),//The text on the button.
        "GUI/InteractionIcons.png",//File name
        Vec2f(32, 32),//Icon frame size
        13,//Default frame
        13,//Hover frame 
        13,//Pressing frame
        "activate",//Command ID
        params//Params
    );
}

*/
