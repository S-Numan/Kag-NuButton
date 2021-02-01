// Chest.as

#include "LootCommon.as";
#include "GenericButtonCommon.as";

void onInit(CBlob@ this)
{
	// Activatable.as adds the following
	// this.Tag("activatable");
	// this.addCommandID("activate");

	// used by RunnerMovement.as & ActivateHeldObject.as
	this.Tag("medium weight");

	AddIconToken("$chest_open$", "InteractionIcons.png", Vec2f(32, 32), 20);
	AddIconToken("$chest_close$", "InteractionIcons.png", Vec2f(32, 32), 13);

	if (getNet().isServer())
	{
		// todo: loot based on gamemode
		CRules@ rules = getRules();

		if (rules.gamemode_name == TDM)
		{
			addLoot(this, INDEX_TDM, 2, 0);
		}
		else if (rules.gamemode_name == CTF)
		{
			addLoot(this, INDEX_CTF, 2, 0);
		}
		addCoin(this, 40 + XORRandom(40));
	}

	CSprite@ sprite = this.getSprite();
	if (sprite !is null)
	{
		u8 team_color = XORRandom(5);
		this.set_u8("team_color", team_color);

		sprite.SetZ(-10.0f);
		sprite.ReloadSprites(team_color, 0);

		if (this.hasTag("_chest_open"))
		{
			sprite.SetAnimation("open");
			sprite.PlaySound("ChestOpen.ogg", 3.0f);
		}
	}
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
    if(this.exists(DROP)){ return; }//Chest only


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
        getTranslatedString("Open"),//The text on the button.
        "GUI/InteractionIcons.png",//File name
        Vec2f(32, 32),//Icon frame size
        13,//Default frame
        13,//Hover frame 
        13,//Pressing frame
        "activate",//Command ID
        params//Params
    );
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("activate"))
	{
		this.AddForce(Vec2f(0, -800));

		if (getNet().isServer())
		{
			u16 id;
			if (!params.saferead_u16(id)) return;

			CBlob@ caller = getBlobByNetworkID(id);
			if (caller is null) return;

			// add guaranteed piece of loot from your class index
			const string NAME = caller.getName();
			if (NAME == "archer")
			{
				addLoot(this, INDEX_ARCHER, 1, 0);
			}
			else if (NAME == "builder")
			{
				addLoot(this, INDEX_BUILDER, 1, 0);
			}
			else if (NAME == "knight")
			{
				addLoot(this, INDEX_KNIGHT, 1, 0);
			}

			server_CreateLoot(this, this.getPosition(), caller.getTeamNum());
		}

		this.Tag("_chest_open");
		this.Sync("_chest_open", true);
		CSprite@ sprite = this.getSprite();
		if (sprite !is null)
		{
			sprite.SetAnimation("open");
			sprite.PlaySound("ChestOpen.ogg", 3.0f);
		}
	}
}

void onDie(CBlob@ this)
{
	if (getNet().isServer() && !this.exists(DROP))
	{
		addLoot(this, INDEX_TDM, 1, 0);
	}

	CSprite@ sprite = this.getSprite();
	if (sprite !is null)
	{
		sprite.Gib();

		makeGibParticle(
		sprite.getFilename(),               // file name
		this.getPosition(),                 // position
		getRandomVelocity(90, 2, 360),      // velocity
		0,                                  // column
		3,                                  // row
		Vec2f(16, 16),                      // frame size
		1.0f,                               // scale?
		0,                                  // ?
		"",                                 // sound
		this.get_u8("team_color"));         // team number
	}
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	return blob.getShape().isStatic() && blob.isCollidable();
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return false;
}