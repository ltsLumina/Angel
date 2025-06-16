class AGlock : AManualGun
{
    default ReloadSteps = 5;

    void Shoot(bool&out Success) override
    {
        Super::Shoot(Success);
        
        
    }
};