﻿Shader "xukmi/EyePlus"
{
	Properties
	{
		_MainTex ("MainTex", 2D) = "white" {}
		[Gamma]_overcolor1 ("overcolor1", Vector) = (1,1,1,1)
		_overtex1 ("overtex1", 2D) = "black" {}
		[Gamma]_overcolor2 ("overcolor2", Vector) = (1,1,1,1)
		_overtex2 ("overtex2", 2D) = "black" {}
		[MaterialToggle] _isHighLight ("isHighLight", Float) = 0
		_expression ("expression", 2D) = "black" {}
		_exppower ("exppower", Range(0, 1)) = 1
		_ExpressionSize ("Expression Size", Range(0, 1)) = 0.35
		_ExpressionDepth ("Expression Depth", Range(0, 2)) = 1
		[Gamma]_shadowcolor ("shadowcolor", Vector) = (0.6298235,0.6403289,0.747,1)
		_rotation ("rotation", Range(0, 1)) = 0
		[HideInInspector] _Cutoff ("Alpha cutoff", Range(0, 1)) = 0.5
		_EmissionMask ("Emission Mask", 2D) = "black" {}
		[Gamma]_EmissionColor("Emission Color", Color) = (1, 1, 1, 1)
		_EmissionIntensity("Emission Intensity", Float) = 1
		[Gamma]_CustomAmbient("Custom Ambient", Color) = (0.666666666, 0.666666666, 0.666666666, 1)
		[MaterialToggle] _UseRampForLights ("Use Ramp For Light", Float) = 1
		_DisablePointLights ("Disable Point Lights", Range(0,1)) = 0.0
		_ShadowHSV ("Shadow HSV", Vector) = (0, 0, 0, 0)
		
		_ReflectMap ("Reflect Body Map", 2D) = "white" {}
		_Roughness ("Roughness", Range(0, 1)) = 0.75
		_ReflectionVal ("ReflectionVal", Range(0, 1)) = 1.0
		[Gamma]_ReflectCol("Reflection Color", Color) = (1, 1, 1, 1)
		_ReflectionMapCap ("Matcap", 2D) = "white" {}
		_UseMatCapReflection ("Use Matcap or Env", Range(0, 1)) = 1.0
		_ReflBlendSrc ("Reflect Blend Src", Float) = 2.0
		_ReflBlendDst ("Reflect Blend Dst", Float) = 0.0
		_ReflBlendVal ("Reflect Blend Val", Range(0, 1)) = 1.0
		_ReflectColMix ("Reflection Color Mix Amount", Range(0,1)) = 1
		_ReflectRotation ("Matcap Rotation", Range(0, 360)) = 0
		_ReflectMask ("Reflect Body Mask", 2D) = "white" {}
		_DisableShadowedMatcap ("Disable Shadowed Matcap", Range(0,1)) = 0.0
	}
	SubShader
	{
		LOD 600
		Tags { "IGNOREPROJECTOR" = "true" "QUEUE" = "Transparent" "RenderType" = "Transparent" }
		
		//Main Pass
		Pass {
			Name "Forward"
			LOD 600
			Tags { "IGNOREPROJECTOR" = "true" "LIGHTMODE" = "FORWARDBASE" "QUEUE" = "Transparent" "RenderType" = "Transparent" "SHADOWSUPPORT" = "true" }
			Blend SrcAlpha OneMinusSrcAlpha, SrcAlpha OneMinusSrcAlpha
			ZWrite Off
			
			Stencil {
				Ref 2
				Comp Always
				Pass Replace
				Fail Keep
				ZFail Keep
			}

			CGPROGRAM
			#pragma target 3.0
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile _ VERTEXLIGHT_ON
			#pragma multi_compile _ SHADOWS_SCREEN

			#define KKP_EXPENSIVE_RAMP

			//Unity Includes
			#include "UnityCG.cginc"
			#include "AutoLight.cginc"
			#include "Lighting.cginc"


			#include "KKPEyeInput.cginc"
			#include "KKPEyeDiffuse.cginc"
			#include "../KKPVertexLights.cginc"
			#include "../KKPEmission.cginc"


			Varyings vert (VertexData v)
			{
				Varyings o;
				o.posWS = mul(unity_ObjectToWorld, v.vertex);
				o.posCS = mul(UNITY_MATRIX_VP, o.posWS);
				o.normalWS = UnityObjectToWorldNormal(v.normal);
				o.tanWS = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);
				float3 biTan = cross(o.tanWS, o.normalWS);
				o.bitanWS = normalize(biTan);
				o.uv0 = v.uv0;
				o.uv1 = v.uv1;
				o.uv2 = v.uv2;
				11111111;
				return o;
			}

			fixed4 frag (Varyings i) : SV_Target
			{

				float4 ambientShadow = 1 - _ambientshadowG.wxyz;
				float3 ambientShadowIntensity = -ambientShadow.x * ambientShadow.yzw + 1;
				float ambientShadowAdjust = _ambientshadowG.w * 0.5 + 0.5;
				float ambientShadowAdjustDoubled = ambientShadowAdjust + ambientShadowAdjust;
				bool ambientShadowAdjustShow = 0.5 < ambientShadowAdjust;
				ambientShadow.rgb = ambientShadowAdjustDoubled * _ambientshadowG.rgb;
				float3 finalAmbientShadow = ambientShadowAdjustShow ? ambientShadowIntensity : ambientShadow.rgb;
				finalAmbientShadow = saturate(finalAmbientShadow);
				float3 invertFinalAmbientShadow = 1 - finalAmbientShadow;

				finalAmbientShadow *= _shadowcolor.xyz;
				finalAmbientShadow = finalAmbientShadow + finalAmbientShadow;

				//This gives a /slightly/ different color than just a one minus for whatever reason
				//The KK shader does this so it's staying in
				float3 shadowColor = _shadowcolor.xyz - 0.5;
				shadowColor = -shadowColor * 2 + 1;
				invertFinalAmbientShadow = -shadowColor * invertFinalAmbientShadow + 1;
				bool3 shadowCheck = 0.5 < _shadowcolor;
				{
					float3 hlslcc_movcTemp = finalAmbientShadow;
					hlslcc_movcTemp.x = (shadowCheck.x) ? invertFinalAmbientShadow.x : finalAmbientShadow.x;
					hlslcc_movcTemp.y = (shadowCheck.y) ? invertFinalAmbientShadow.y : finalAmbientShadow.y;
					hlslcc_movcTemp.z = (shadowCheck.z) ? invertFinalAmbientShadow.z : finalAmbientShadow.z;
					finalAmbientShadow = hlslcc_movcTemp;
				}
				finalAmbientShadow = saturate(finalAmbientShadow);
				float2 uv = i.uv0 - 0.5;
				float angle = _rotation * 6.28318548;
				float rotCos = cos(angle);
				float rotSin = sin(angle);
				float3 rotation = float3(-rotSin, rotCos, rotSin);
				float2 dotRot = float2(dot(uv, rotation.yz), dot(uv, rotation.xy));
				uv = dotRot + 0.5;
				uv = uv * _MainTex_ST.xy + _MainTex_ST.zw;
				float4 iris = tex2D(_MainTex, uv);
				float3 viewDir = normalize(_WorldSpaceCameraPos - i.posWS);
				float2 expressionUV = float2(dot(i.tanWS, viewDir),
									   dot(i.bitanWS, viewDir));
				//Gives some depth
				expressionUV = expressionUV * -0.059999998 * _ExpressionDepth + i.uv0;
				expressionUV = expressionUV * _MainTex_ST.xy + _MainTex_ST.zw; //Makes expression follow eye
				expressionUV -= 0.5;
				expressionUV /= max(0.1, _ExpressionSize);
				expressionUV += 0.5;
				float4 expression = tex2D(_expression, expressionUV + float2(0, 0.1));
				expression.rgb =  expression.rgb - iris.rgb;
				expression.a *= _exppower;
				float3 diffuse = expression.a * expression.rgb + iris.rgb;


				float4 overTex1 = tex2D(_overtex1, i.uv1 * _overtex1_ST + _overtex1_ST.zw);
				overTex1 = overTex1.a * _overcolor1.rgba;
				float4 overTex2 = tex2D(_overtex2, i.uv2 * _overtex2_ST + _overtex2_ST.zw);
				overTex2 = overTex2.a * _overcolor2.rgba;
				float4 overTex = max(overTex1, overTex2);
				float3 blendOverTex = overTex.rgb - diffuse;
				overTex.a = saturate(overTex.a * _isHighLight);
				diffuse = overTex.a * blendOverTex + diffuse;
				float alpha = saturate(max(max(overTex.a, expression.a), iris.a));

				float3 shadedDiffuse = diffuse * finalAmbientShadow;
				finalAmbientShadow = -diffuse * finalAmbientShadow + diffuse;


				KKVertexLight vertexLights[4];
			#ifdef VERTEXLIGHT_ON
				GetVertexLightsTwo(vertexLights, i.posWS, _DisablePointLights);	
			#endif
				float4 vertexLighting = 0.0;
				float vertexLightRamp = 1.0;
			#ifdef VERTEXLIGHT_ON
				vertexLighting = GetVertexLighting(vertexLights, i.normalWS);
				float2 vertexLightRampUV = vertexLighting.a * _RampG_ST.xy + _RampG_ST.zw;
				vertexLightRamp = tex2D(_RampG, vertexLightRampUV).x;
				float3 rampLighting = GetRampLighting(vertexLights, i.normalWS, vertexLightRamp);
				vertexLighting.rgb = _UseRampForLights ? rampLighting : vertexLighting.rgb;
			#endif
				float lambert = max(dot(_WorldSpaceLightPos0.xyz, i.normalWS.xyz), 0.0) + vertexLighting.a;
				lambert = saturate(expression.a + overTex.a + lambert);
				finalAmbientShadow = lambert * finalAmbientShadow + shadedDiffuse;
				
				float shadowAttenuation = saturate(tex2D(_RampG, lambert * _RampG_ST.xy + _RampG_ST.zw).x);
				#ifdef SHADOWS_SCREEN
					float2 shadowMapUV = i.shadowCoordinate.xy / i.shadowCoordinate.ww;
					float4 shadowMap = tex2D(_ShadowMapTexture, shadowMapUV);
					shadowAttenuation *= shadowMap;
				#endif

				float3 lightCol = (_LightColor0.xyz + vertexLighting.rgb * vertexLightRamp) * float3(0.600000024, 0.600000024, 0.600000024) + _CustomAmbient;
				lightCol = max(lightCol, _ambientshadowG.xyz);
				float3 finalCol = finalAmbientShadow * lightCol;
				
				float3 hsl = RGBtoHSL(finalCol);
				hsl.x = hsl.x + _ShadowHSV.x;
				hsl.y = hsl.y + _ShadowHSV.y;
				hsl.z = hsl.z + _ShadowHSV.z;
				finalCol = lerp(HSLtoRGB(hsl), finalCol, saturate(shadowAttenuation + 0.5));

				// Overlay emission over expression
				float4 emission = GetEmission(expressionUV);
				finalCol = finalCol * (1 - emission.a) + (emission.a * emission.rgb);
				
				return float4(finalCol, alpha);
			}
			ENDCG
		}

		//Reflection Pass
		Pass {
			Name "Reflect"
			LOD 600
			Tags { "IGNOREPROJECTOR" = "true" "LIGHTMODE" = "FORWARDBASE" "QUEUE" = "Transparent" "RenderType" = "Transparent" "SHADOWSUPPORT" = "true" }
			Blend [_ReflBlendSrc] [_ReflBlendDst]
			ZWrite Off
			
			CGPROGRAM
			#pragma target 3.0
			#pragma vertex vert
			#pragma fragment reflectfrag
			
			#pragma multi_compile _ VERTEXLIGHT_ON
			#pragma multi_compile _ SHADOWS_SCREEN
			
			#define KKP_EXPENSIVE_RAMP

			//Unity Includes
			#include "UnityCG.cginc"
			#include "AutoLight.cginc"
			#include "Lighting.cginc"
			
			#include "KKPEyeInput.cginc"
			#include "KKPEyeDiffuse.cginc"
			#include "../KKPVertexLights.cginc"
			
			#include "KKPEyeReflect.cginc"

			Varyings vert (VertexData v)
			{
				Varyings o;
				o.posWS = mul(unity_ObjectToWorld, v.vertex);
				o.posCS = UnityObjectToClipPos(v.vertex);
				o.normalWS = UnityObjectToWorldNormal(v.normal);
				o.tanWS = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);
				float3 biTan = cross(o.tanWS, o.normalWS);
				o.bitanWS = normalize(biTan);
				o.uv0 = v.uv0;
				return o;
			}
			ENDCG
		}
	}
	Fallback "Diffuse"
}
