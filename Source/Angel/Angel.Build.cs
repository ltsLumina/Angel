

using UnrealBuildTool;

public class Angel : ModuleRules
{
	public Angel(ReadOnlyTargetRules Target) : base(Target)
	{
		PCHUsage = PCHUsageMode.UseExplicitOrSharedPCHs;

		PublicDependencyModuleNames.AddRange
		([ "Core", "CoreUObject", "InputCore", "Engine",
		   "AngelscriptGAS", "GameplayAbilities", "GameplayTags", "GameplayTasks" ]);

		if (Target.bBuildEditor)
		{
			PrivateDependencyModuleNames.AddRange([ "UnrealEd", "BlueprintGraph", "Slate", "SlateCore" ]);
		}

		PrivateDependencyModuleNames.AddRange([]);

		// Uncomment if you are using Slate UI
		// PrivateDependencyModuleNames.AddRange(new string[] { "Slate", "SlateCore" });
		
		// Uncomment if you are using online features
		// PrivateDependencyModuleNames.Add("OnlineSubsystem");

		// To include OnlineSubsystemSteam, add it to the plugins section in your uproject file with the Enabled attribute set to true
	}
}
