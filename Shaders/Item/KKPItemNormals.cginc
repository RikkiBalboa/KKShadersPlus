﻿#ifndef KKP_ITEMNORMAL_INC
#define KKP_ITEMNORMAL_INC

float3 GetNormal(Varyings i){	
	//Normals
	float2 normalUV = i.uv0 + _NormalMap_ST.xy + _NormalMap_ST.zw;
	float3 normalMap = UnpackScaleNormal(tex2D(_NormalMap, normalUV), _NormalMapScale);
	return normalMap;
}

float3 CreateBinormal (float3 normal, float3 tangent, float binormalSign) {
	return cross(normal, tangent.xyz) *
		(binormalSign * unity_WorldTransformParams.w);
}

//KK uses VFACE to flip the normals, but that seems to break in reflection probes which is what messes up the lighting in mirrors
float3 NormalAdjust(Varyings i, float3 finalCombinedNormal, int faceDir){
	//Adjusting normals from tangent space
	float3 normal = finalCombinedNormal;

	float3 binormal = CreateBinormal(i.normalWS, i.tanWS.xyz, i.tanWS.w);
	normal = normalize(
		finalCombinedNormal.x * i.tanWS +
		finalCombinedNormal.y * binormal +
		finalCombinedNormal.z * i.normalWS
	);

	//This give some items correct shading on backfaces but messes up mirror shading
	//adjustedNormal.z *= faceDir <= 0 ? -1 : 1;

	return normal;
}

#endif