

using UnrealBuildTool;
using System.Collections.Generic;

public class AngelEditorTarget : TargetRules
{
	public AngelEditorTarget(TargetInfo Target) : base(Target)
	{
		Type = TargetType.Editor;
		DefaultBuildSettings = BuildSettingsVersion.V7;

		ExtraModuleNames.AddRange( new string[] { "Angel" } );
	}
}
