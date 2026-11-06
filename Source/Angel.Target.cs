

using UnrealBuildTool;
using System.Collections.Generic;

public class AngelTarget : TargetRules
{
	public AngelTarget(TargetInfo Target) : base(Target)
	{
		Type = TargetType.Game;
		DefaultBuildSettings = BuildSettingsVersion.V7;

		ExtraModuleNames.AddRange( new string[] { "Angel" } );
	}
}
