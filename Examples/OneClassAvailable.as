// OneClassAvailable.as

#include "StandardRespawnCommand.as";
#include "GenericButtonCommon.as";
#include "NuLib.as";

const string req_class = "required class";

void onInit(CBlob@ this)
{
	this.Tag("change class drop inventory");
	if (!this.exists("class offset"))
		this.set_Vec2f("class offset", Vec2f_zero);

	if (!this.exists("class button radius"))
	{
		CShape@ shape = this.getShape();
		if (shape !is null)
		{
			this.set_u8("class button radius", Maths::Max(this.getRadius(), (shape.getWidth() + shape.getHeight()) / 2));
		}
		else
		{
			this.set_u8("class button radius", 16);
		}
	}
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
    if (!canSeeButtons(this, caller,
    false,//Team only //Make true later todo numan notice remove this
    9999.0f)//Max distance
    || !this.exists(req_class))
    {
        return;
    }

    Vec2f _offset = this.get_Vec2f("class offset");//Quick fix for bad offsets.
    if(Maths::Abs(_offset.x) == 6)
    {
        _offset.x *= 2;
    }


    string cfg = this.get_string(req_class);

    if (canChangeClass(this, caller) && caller.getName() != cfg)
	{
		CBitStream params;
		write_classchange(params, caller.getNetworkID(), cfg);

        //Sets up things easily.
        NuMenu::MenuButton@ button = CreateButtonFull(this,//The blob this button will follow. 
            caller,//The player blob.
            getTranslatedString("Swap Class"),//The text on the button.
            "GUI/InteractionIcons.png",//File name
            Vec2f(32, 32),//Icon frame size
            14,//Default frame
            14,//Hover frame 
            14,//Pressing frame
            SpawnCmd::changeClass,//Command ID
            params//Params
        );
        button.setOffset(_offset);

		button.enableRadius = this.get_u8("class button radius");
	}


}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	onRespawnCommand(this, cmd, params);
}