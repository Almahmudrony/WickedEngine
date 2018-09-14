#include "globals.hlsli"
#include "hairparticleHF.hlsli"
#include "ShaderInterop_HairParticle.h"

static const float hairPopDistanceThreshold = 0.9f;

// billboard cross section:
static const float3 HAIRPATCH[] = {
	float3(-1, -1, 0),
	float3(1, -1, 0),
	float3(-1, 1, 0),
	float3(-1, 1, 0),
	float3(1, -1, 0),
	float3(1, 1, 0),

	float3(0, -1, -1),
	float3(0, -1, 1),
	float3(0, 1, -1),
	float3(0, 1, -1),
	float3(0, -1, 1),
	float3(0, 1, 1),
};

STRUCTUREDBUFFER(particleBuffer, Patch, 0);

VertexToPixel main(uint fakeIndex : SV_VERTEXID)
{
	VertexToPixel Out;

	// bypass the geometry shader and expand the particle here:
	uint vertexID = fakeIndex % 12;
	uint instanceID = fakeIndex / 12;

	// convert the raw loaded particle data:
	float3 position = particleBuffer[instanceID].position;
	uint tangent_random = particleBuffer[instanceID].tangent_random;
	float3 normal = particleBuffer[instanceID].normal;
	uint binormal_length = particleBuffer[instanceID].binormal_length;

	float3 tangent;
	tangent.x = (tangent_random >> 0) & 0x000000FF;
	tangent.y = (tangent_random >> 8) & 0x000000FF;
	tangent.z = (tangent_random >> 16) & 0x000000FF;
	tangent = tangent / 255.0f * 2 - 1;

	uint rand = (tangent_random >> 24) & 0x000000FF;

	float3 binormal;
	binormal.x = (binormal_length >> 0) & 0x000000FF;
	binormal.y = (binormal_length >> 8) & 0x000000FF;
	binormal.z = (binormal_length >> 16) & 0x000000FF;
	binormal = binormal / 255.0f * 2 - 1;

	float length = (binormal_length >> 24) & 0x000000FF;
	length /= 255.0f;
	length += 1;
	length *= xLength;

	// expand the particle into a billboard cross section, the patch:
	float3 patchPos = HAIRPATCH[vertexID];
	float2 uv = vertexID < 6 ? patchPos.xy : patchPos.zy;
	uv = uv * float2(0.5f, -0.5f) + 0.5f;
	uv.x = rand % 2 == 0 ? uv.x : 1 - uv.x;
	patchPos.y += 1;

	// scale the billboard by the texture aspect:
	float2 frame;
	texture_0.GetDimensions(frame.x, frame.y);
	frame.xy /= frame.y;
	frame.xy *= length;
	patchPos.xyz *= frame.xyx * 0.5f;

	// simplistic wind effect only affects the top, but leaves the base as is:
	float3 wind = sin(g_xFrame_Time + (position.x + position.y + position.z))*g_xFrame_WindDirection.xyz * patchPos.y * 0.03f;
	float3 windPrev = sin(g_xFrame_TimePrev + (position.x + position.y + position.z))*g_xFrame_WindDirection.xyz * patchPos.y * 0.03f;

	// transform particle by the emitter object matrix:
	position.xyz = mul(xWorld, float4(position.xyz, 1)).xyz;
	normal = normalize(mul((float3x3)xWorld, normal));
	tangent = normalize(mul((float3x3)xWorld, tangent));

	// rotate the patch into the tangent space of the emitting triangle:
	//float3x3 TBN = float3x3(tangent, normal, cross(normal, tangent));
	float3x3 TBN = float3x3(tangent, normal, binormal); // don't derive binormal, because we want the shear!
	patchPos = mul(patchPos, TBN);

	// inset to the emitter a bit, to avoid disconnect:
	position.xyz -= normal * 0.1 * length;


	// copy to output:
	Out.pos = float4(position, 1);
	Out.pos.xyz += patchPos;
	float3 savedPos = Out.pos.xyz;
	Out.pos.xyz += wind;
	Out.pos3D = Out.pos.xyz;
	Out.pos = mul(Out.pos, g_xCamera_VP);

	Out.nor = normal;
	Out.tex = uv; 
	
	Out.fade = pow(saturate(distance(position.xyz, g_xCamera_CamPos.xyz) / (LOD2*hairPopDistanceThreshold)), 10);
	Out.pos2D = Out.pos;
	Out.pos2DPrev = mul(float4(savedPos + windPrev, 1), g_xFrame_MainCamera_PrevVP);

	Out.color = xColor.rgb;

	return Out;
}
