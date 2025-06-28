// Custom item ID type for inventory
struct FItemID
{
    // Contains the full ID, which can include a prefix and category
    UPROPERTY()
    FName FullID;

    FItemID() { FullID = FName(""); }
    FItemID(FName InID) { FullID = InID; }
    FItemID(const FString& InID) { FullID = FName(InID); }

    // Returns the part after the colon, or the full string if no colon
    FString GetShortID() const
    {
        FString Str = FullID.ToString();
        int32 ColonIdx = Str.Find(":");
        if (ColonIdx != -1 && ColonIdx + 1 < Str.Len())
        {
            return Str.Mid(ColonIdx + 1);
        }
        return Str;
    }

    bool Equals(const FItemID& Other) const
    {
        return GetShortID().Equals(Other.GetShortID(), ESearchCase::IgnoreCase);
    }

    // Allow comparison with FName directly (by short ID)
    bool EqualsFName(const FName& OtherName) const
    {
        FString OtherStr = OtherName.ToString();
        int32 ColonIdx = OtherStr.Find(":");
        if (ColonIdx != -1 && ColonIdx + 1 < OtherStr.Len())
        {
            OtherStr = OtherStr.Mid(ColonIdx + 1);
        }
        return GetShortID().Equals(OtherStr, ESearchCase::IgnoreCase);
    }
};

struct FInventorySlot
{
    // Unique identifier for the item slot, can be used to reference the item in the inventory
    UPROPERTY(VisibleAnywhere)
    FItemID ID;

    UPROPERTY()
    UItemData ItemDefinition;

    UPROPERTY()
    int32 Quantity = 1;

    // Defines the item instance data, such as durability, enchantments, etc.
    UPROPERTY(Meta = (EditCondition = "IsStackable", EditConditionHides))
    UItemInstanceData InstanceData;

    bool IsStackable() const
    {
        return ItemDefinition != nullptr && ItemDefinition.IsStackable;
    }
};

class UItemData : UDataAsset
{
    UPROPERTY(DisplayName = "Name")
    FText ItemName = FText::FromName(GetName());

    UPROPERTY()
    FText Description = FText::FromString("Default item description.");

    UPROPERTY()
    UTexture2D Icon;

    UPROPERTY(AdvancedDisplay)
    FName Category = NAME_None; 

    // -- 

    // If true, only one instance of this item can exist in the inventory at a time.
    UPROPERTY()
    bool IsUnique = false;

    UPROPERTY(Meta = (EditCondition = "IsUnique", EditConditionHides))
    TSubclassOf<UItemInstanceData> InstanceDataClass;

    UPROPERTY()
    bool IsStackable = true;

    UPROPERTY(Meta = (EditCondition = "IsStackable", EditConditionHides))
    int MaxStackSize = 64;
    default MaxStackSize = IsStackable ? MaxStackSize : 1;
}

class UItemInstanceData : UObject
{
    UPROPERTY(BlueprintReadOnly, Category = "Item Instance")
    UItemData ItemDefinition;

    UPROPERTY(Category = "Item Instance")
    int32 Durability = 100;

    UPROPERTY(Category = "Item Instance")
    TArray<FName> Enchantments; // List of enchantments applied to this item instance

    // optional: enchantments, custom properties, owner, etc.
};

class UInventoryComponent : UActorComponent
{
    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Inventory")
    TArray<FInventorySlot> InventorySlots;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        ClearInventory();

        if (!IsInventoryValid())
        {
            PrintError("Inventory is not valid at BeginPlay. Clearing inventory.");
            ClearInventory();
        }

        BP_BeginPlay();
    }

    UFUNCTION(BlueprintEvent, DisplayName = "Begin Play")
    void BP_BeginPlay() { }

    UFUNCTION(BlueprintPure, Category = "Inventory")
    FInventorySlot GetItemByID(FItemID ItemID)
    {
        for (FInventorySlot& Slot : InventorySlots)
        {
            if (Slot.ID.Equals(ItemID))
            {
                return Slot;
            }
        }
        Print(f"Item with ID '{ItemID.GetShortID()}' not found in inventory.", 5.0f, FLinearColor::Yellow);
        return FInventorySlot(); // Return an empty slot if not found
    }

    /**
      * Adds an item to the player's inventory.
      * @param Data The item data to add.
      * @param Quantity The quantity of the item to add.
      * @param Instanced If true, creates an item instance data for the item. (e.g, durability, enchantments)
      * @param OutputSlots Array of all slots added or modified.
    * @param OutputSlot Output parameter for the first slot added or modified (unique items only).
    */
    UFUNCTION(Category = "Inventory", Meta = (AdvancedDisplay = "OutputSlots, OutputSlot"))
    void AddItem(UItemData Data, int32 Quantity = 1, FInventorySlot&out OutputSlot = FInventorySlot(), TArray<FInventorySlot>&out OutputSlots = TArray<FInventorySlot>())
    {
      OutputSlots.Empty();
      OutputSlot = FInventorySlot();

      if (Data == nullptr || Quantity <= 0)
      {
        PrintError("Invalid item data or quantity.");
        return;
      }

      // Validate all existing slots before adding
      if (!IsInventoryValid(true))
      {
        PrintError("Inventory contains invalid slots. Aborting AddItem.");
        return;
      }

      // Handle unique items: only one allowed in inventory
      if (Data.IsUnique)
      {
        for (const FInventorySlot& Item : InventorySlots)
        {
            if (Item.ItemDefinition == Data)
            {
              Print(f"Unique item '{Data.GetName()}' already exists in inventory.", 5.0f, FLinearColor::Red);
              return;
            }
        }
        // Add the unique item as a single slot
        FInventorySlot UniqueSlot;
        UniqueSlot.ID = FItemID(GenerateUniqueID(Data));
        UniqueSlot.ItemDefinition = Data;
        UniqueSlot.Quantity = 1;
        CreateInstanceData(UniqueSlot, UniqueSlot.ItemDefinition.InstanceDataClass, UniqueSlot.InstanceData);
        InventorySlots.Add(UniqueSlot);
        OutputSlots.Add(UniqueSlot);
        OutputSlot = UniqueSlot;

        // Validate all slots after adding
        if (!IsInventoryValid(true))
        {
            PrintError("Inventory contains invalid slots after adding item.");
            ClearInventory();
        }
        return;
      }

      int32 RemainingQuantity = Quantity;

      if (Data.IsStackable)
      {
        for (FInventorySlot& Item : InventorySlots)
        {
            if (Item.ItemDefinition == Data && Item.IsStackable() && Item.Quantity < Data.MaxStackSize)
            {
              int32 Space = Data.MaxStackSize - Item.Quantity;
              int32 ToAdd = Math::Min(Space, RemainingQuantity);
              Item.Quantity += ToAdd;
              RemainingQuantity -= ToAdd;
              OutputSlots.Add(Item);
              if (RemainingQuantity <= 0)
              {
                // Validate all slots after adding
                if (!IsInventoryValid(true))
                {
                    PrintError("Inventory contains invalid slots after adding item.");
                    ClearInventory();
                }
                return; // All requested quantity added
              }
            }
        }

        // Add new stack if needed
        while (RemainingQuantity > 0)
        {
            int32 ToAdd = Math::Min(Data.MaxStackSize, RemainingQuantity);

            FInventorySlot NewStack;
            NewStack.ID = FItemID(GenerateUniqueID(Data));
            NewStack.ItemDefinition = Data;
            NewStack.Quantity = ToAdd;
            InventorySlots.Add(NewStack);
            OutputSlots.Add(NewStack);
            RemainingQuantity -= ToAdd;
        }
      }
      else
      {
        // If the item is not stackable, add it as a new slot for each quantity
        for (int32 i = 0; i < RemainingQuantity; ++i)
        {
            FInventorySlot NewSlot;
            NewSlot.ID = FItemID(GenerateUniqueID(Data));
            NewSlot.ItemDefinition = Data;
            NewSlot.Quantity = 1; // Each instance has a quantity of 1
            InventorySlots.Add(NewSlot);
            OutputSlots.Add(NewSlot);
        }
      }

      // Validate all slots after adding everything
      if (!IsInventoryValid(true))
      {
        PrintError("Inventory contains invalid slots after adding item(s).");
        ClearInventory();
      }
    }

    FName GenerateUniqueID(UItemData Data)
    {
        FString ItemName = Data.ItemName.ToString();
        if (ItemName.IsEmpty())
        {
            PrintError("Item name is empty, cannot generate unique ID.");
            return FName("angel:invalid_item_name");
        }

        FString ItemNameSanitized = ItemName.Replace(" ", "_").Replace(":", "_").Replace(".", "_").Replace("-", "_");
        FString Prefix = "angel";
        
        FName Category = Data.Category;
        if (!Category.IsNone())
        {
            FString Sanitized = Category.ToString();
            Sanitized = Sanitized.Replace(" ", "_").Replace(":", "_").Replace(".", "_").Replace("-", "_");
            Category = FName(Sanitized);
        }

        FString UniqueName;
        if (!Category.IsNone())
        {
            UniqueName = f"{Prefix}:{Category}_{ItemNameSanitized}";
        }
        else
        {
            UniqueName = f"{Prefix}:{ItemNameSanitized}";
        }

        return FName(UniqueName.ToLower());
    }

    UFUNCTION(Category = "Inventory")
    void CreateInstanceData(FInventorySlot& ItemSlot, TSubclassOf<UItemInstanceData> InstanceClass, UItemInstanceData&out InstanceData)
    {
        UItemInstanceData Instance;
        Instance = NewObject(this, InstanceClass, FName(f"{ItemSlot.ItemDefinition.ItemName} | Instance Data"), true); // TODO: If I ever want to save the inventory to disk, I need to set bTransient to false
        InstanceData = Instance;
        InstanceData.ItemDefinition = ItemSlot.ItemDefinition;

        ItemSlot.InstanceData = InstanceData;
    }

    /**
      * Removes an item from the player's inventory.
      * @param ItemID The ID of the item to remove.
      * @param Quantity The quantity of the item to remove.
      * @return True if the item was successfully removed, false otherwise.
      */
    UFUNCTION(Category = "Inventory")
    bool RemoveItem(FItemID ItemID, int32 Quantity = 1)
    {
        for (int32 i = 0; i < InventorySlots.Num(); ++i)
        {
            FInventorySlot& Slot = InventorySlots[i];
            if (Slot.ID.Equals(ItemID))
            {
                if (Slot.Quantity >= Quantity)
                {
                    Slot.Quantity -= Quantity;
                    if (Slot.Quantity <= 0)
                    {
                        InventorySlots.RemoveAt(i);
                    }
                    Print(f"Removed {Quantity} of item '{ItemID.GetShortID()}' from inventory.", 5.0f, FLinearColor::Green);
                    return true;
                }
                else
                {
                    PrintError(f"Not enough quantity of item '{ItemID.GetShortID()}' to remove. Available: {Slot.Quantity}, Requested: {Quantity}");
                    return false;
                }
            }
        }
        PrintError(f"Item with ID '{ItemID.GetShortID()}' not found in inventory.");
        return false;
    }

    /**
      * Checks if the inventory contains a specific item.
      * @param ItemID The ID of the item to check.
      * @param Quantity The quantity of the item to check for.
      * @return True if the item exists in the inventory with sufficient quantity, false otherwise.
      */
    UFUNCTION(BlueprintPure, Category = "Inventory", Meta = (AdvancedDisplay = "Quantity"))
    bool HasItem(FItemID ItemID, int32 Quantity = 1) const
    {
        for (const FInventorySlot& Slot : InventorySlots)
        {
            if (Slot.ID.Equals(ItemID) && Slot.Quantity >= Quantity)
            {
                return true;
            }
        }
        return false;
    }

    /**
      * Checks if the inventory is valid.
      * An inventory is considered valid if all slots have a valid item definition and a positive quantity.
      * @param ValidateQuantity If true, also checks if the quantity of each item is greater than zero.
      * @return True if the inventory is valid, false otherwise.
      */
    UFUNCTION(BlueprintPure, Category = "Inventory", Meta = (AdvancedDisplay = "ValidateQuantity"))
    bool IsInventoryValid(bool ValidateQuantity = false) const
    {
        // iterate through the inventory slots and check if each slot has a valid item definition
        for (const FInventorySlot& Slot : InventorySlots)
        {
            if (Slot.ItemDefinition == nullptr)
            {
                return false;
            }

            if (Slot.ItemDefinition.ItemName.IsEmptyOrWhitespace())
            {
                return false;
            }

            // Optionally, you can also check if the quantity is valid
            if (ValidateQuantity && Slot.Quantity <= 0)
            {
                return false;
            }
        }

        return true;
    }

    UFUNCTION(Category = "Inventory")
    void ClearInventory()
    {
        InventorySlots.Empty();
    }

    UFUNCTION(BlueprintPure, Category = "Inventory")
    TArray<FInventorySlot> GetInventory() const
    {
        return InventorySlots;
    }
};

UFUNCTION(BlueprintPure, Category = "Inventory")
FInventorySlot GetItemByID(UInventoryComponent InventoryComponent, FItemID ItemID)
{
    for (const FInventorySlot& Slot : InventoryComponent.InventorySlots)
    {
        if (Slot.ID.Equals(ItemID))
        {
            return Slot;
        }
    }
    Print(f"Item with ID '{ItemID.GetShortID()}' not found in inventory.", 5.0f, FLinearColor::Yellow);
    return FInventorySlot(); // Return an empty slot if not found        
}