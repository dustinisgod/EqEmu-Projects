TradeIt.lua - Trade Items or Coins to PC/NPC

This script provides an easy-to-use interface for trading items or coins to player characters (PCs) or non-player characters (NPCs). It includes auto-fill features for item and player names, drag-and-drop support for items, and the ability to quickly distribute coins to group or raid members.

Key Features:

Drag and Drop: 
    You can drag and drop items from your inventory onto the window, and the item name will automatically populate the item field.

Auto-complete:
        Item Names: Start typing the name of an item, and it will auto-complete based on the items in your inventory.
        Player Names: Begin typing the name of a player, and the script will search for matches in your group, raid, or any PC within 200 units of your character.
        NPC Names: If you start typing a name, any NPC within 200 units will also appear as an auto-complete suggestion.

Tab Key: 
    Use the Tab key to auto-complete suggested names and move to the next input field.

Group and Raid Coin Distribution:
        Group Coin Trade: The script allows you to distribute a specified amount of coins to each member of your group within 200 units.
        Raid Coin Trade: Similarly, you can distribute coins to each member of your raid who is within 200 units.

Commands:


Show/Hide Window:

        /tradeithide – Hides the TradeIt GUI window.
        /tradeitshow – Shows the TradeIt GUI window.


--Coin Trade Command: You can trade coins to a specified target using this command.

    Format:
    /tradeit coin <target_name> <coin_type> <amount>

    Supported Coin Types:
        platinum
        gold
        silver
        copper

Example:
    /tradeit coin jackthebarb platinum 2450
    This command will trade 2450 platinum to the player named Jackthebarb.

--Item Trade Command: You can trade an item by specifying the item name and quantity.

        Format:
        /tradeit item <target_name> <item_name> <quantity>

        Example:
        /tradeit item legolas longbow 1
        This command will trade 1 longbow to Legolas.

--Group Coin Distribution: Distribute a set amount of coins to all group members within 200 units.

        Format:
        /tradeit group coin <coin_type> <amount>

        Example:
        /tradeit group coin platinum 500
        This will distribute 500 platinum to each group member.

--Raid Coin Distribution: Distribute coins to all raid members within 200 units.

        Format:
        /tradeit raid coin <coin_type> <amount>

        Example:
        /tradeit raid coin silver 1000
        This will distribute 1000 silver coins to each raid member.



dragcorpse.lua – Automatically drags nearby corpses that belong to group or raid members, or yourself, stopping at a group/raid cleric for resurrection. Ideal with two pullers working together to ensure no corpses are left behind, even if one puller dies.

lootcorpse.lua – Summons and loots your own corpses automatically. Perfect for EMU servers where corpses persist after resurrection.

guild-invite.lua – Automatically invites any player in your Dannet network to your guild, provided the character running the script has invite permissions.

mend.lua – Uses the monk's Mend ability whenever it's available, helping you train it efficiently.

feign.lua – Repeatedly uses Feign Death on your monk as soon as it’s available to maximize skill training.