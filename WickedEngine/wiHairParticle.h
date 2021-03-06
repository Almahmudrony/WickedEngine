#pragma once
#include "wiParticle.h"
#include "ConstantBufferMapping.h"
#include "wiSPTree.h"

struct Material;
struct Camera;

class wiArchive;

class wiHairParticle :
	public wiParticle
{
public:
	GFX_STRUCT Point
	{
		XMFLOAT4 posRand;
		XMFLOAT4 normalLen;
		XMFLOAT4 tangent;

		ALIGN_16
	};
private:
	GFX_STRUCT ConstantBuffer
	{
		XMMATRIX mWorld;
		XMFLOAT3 color; float __pad0;
		float LOD0;
		float LOD1;
		float LOD2;
		float __pad1;

		CB_SETBINDSLOT(CBSLOT_OTHER_HAIRPARTICLE)

		ALIGN_16
	};
	static wiGraphicsTypes::VertexLayout *il;
	static wiGraphicsTypes::VertexShader *vs;
	static wiGraphicsTypes::PixelShader *ps[SHADERTYPE_COUNT], *qps[SHADERTYPE_COUNT];
	static wiGraphicsTypes::GeometryShader *gs,*qgs;
	static wiGraphicsTypes::GPUBuffer *cbgs;
	static wiGraphicsTypes::DepthStencilState *dss;
	static wiGraphicsTypes::RasterizerState *rs,*ncrs;
	static wiGraphicsTypes::BlendState *bs;
	static int LOD[3];
public:
	static void LoadShaders();

public:
	wiHairParticle();
	wiHairParticle(const string& newName, float newLen, int newCount
		, const string& newMat, Object* newObject, const string& densityGroup, const string& lengthGroup);
	void CleanUp();

	void Generate();
	void Draw(Camera* camera, SHADERTYPE shaderType, GRAPHICSTHREAD threadID);

	static void CleanUpStatic();
	static void SetUpStatic();
	static void Settings(int lod0,int lod1,int lod2);

	float length;
	int count;
	string name, densityG, lenG, materialName;
	Material* material;
	XMFLOAT4X4 OriginalMatrix_Inverse;
	Object* object;
	vector<Point> points;
	wiGraphicsTypes::GPUBuffer *vb;

	void Serialize(wiArchive& archive);
};

