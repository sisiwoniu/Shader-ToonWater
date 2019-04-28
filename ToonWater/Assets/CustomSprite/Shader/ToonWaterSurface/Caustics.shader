//水面下の効果のシェーダー
Shader "CustomShader/Caustics"
{
    Properties
    {
		_Color("Main Color", Color) = (0, 0, 1, 0.7)
		_ColorT("Tint", Color) = (0, 1, 1, 0.6)
		_Mask("Mask", 2D) = "white" {}
		_Noise("Noise", 2D) = "black" {}
		_Tile("Tile", 2D) = "white" {}
		_FallOffTex("FallOff", 2D) = "white" {}
		_Scale("Scale", Range(0, 1)) = 0.1
		_Speed("Speed", Range(0, 10)) = 1
		_Intensity("Intensity", Range(0, 10)) = 5
		_NoiseScale("NoiseScale", Range(0, 1)) = 0.1
		[Enum(UnityEngine.Rendering.BlendMode)]_SrcBlendMode("SrcBlendMode", int) = 5
		[Enum(UnityEngine.Rendering.BlendMode)]_DstBlendMode("DstBlendMode", int) = 10
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Transparent" }
        
		LOD 100

        Pass
        {
			ZWrite off

			Cull off

			ColorMask RGB

			Blend [_SrcBlendMode] [_DstBlendMode]

			//Zファイティング対策
			Offset -1, -1

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
				float4 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
				float4 uvFalloff : TEXCOORD1;
				float3 worldPos : TEXCOORD2;
				float3 worldNormal : TEXCOORD3;
				float4 uvMask : TEXCOORD4;
            };

            fixed4 _Color, _ColorT;

			sampler2D _Mask, _Noise, _Tile, _FallOffTex;

			half _Scale, _Speed, _Intensity, _NoiseScale;

			float4x4 unity_Projector;

			float4x4 unity_ProjectorClip;

            v2f vert (appdata v)
            {
                v2f o;

				o.uv = v.uv;

                o.vertex = UnityObjectToClipPos(v.vertex);

				o.uvFalloff = mul(unity_ProjectorClip, v.vertex);

				o.uvMask = mul(unity_Projector, v.vertex);

				o.worldPos = mul(unity_ObjectToWorld, v.vertex);

				o.worldNormal = normalize(mul(v.normal, unity_ObjectToWorld));

                return o;
            }

			fixed4 triplanar(float3 blendNormal, float4 texturex, float4 texturey, float4 texturez) 
			{
				float4 triplanartexture = texturez;

				triplanartexture = lerp(triplanartexture, texturex, blendNormal.x);

				triplanartexture = lerp(triplanartexture, texturey, blendNormal.y);

				return triplanartexture;
			}

            fixed4 frag (v2f i) : SV_Target
            {
				
				half speed = _Time.x * _Speed;

				float3 blendNormal = saturate(pow(i.worldNormal * 1.4, 4));

				//distortion
				float4 distortx = tex2D(_Noise, float2(i.worldPos.zy * _NoiseScale) - speed);

				float4 distorty = tex2D(_Noise, float2(i.worldPos.xz * _NoiseScale) - speed);

				float4 distortz = tex2D(_Noise, float2(i.worldPos.xy * _NoiseScale) - speed);
				
				float4 distort = triplanar(blendNormal, distortx, distorty, distortz);

				//moving Caustics
				float3 worldPos = i.worldPos + distort.xyz;

				fixed4 xc = tex2D(_Tile, float2(worldPos.z, worldPos.y * _Scale * 0.25));

				fixed4 zc = tex2D(_Tile, float2(worldPos.x, worldPos.y * _Scale * 0.25));

				fixed4 yc = tex2D(_Tile, float2(worldPos.y, worldPos.z) * _Scale);

				fixed4 causticsTex = triplanar(blendNormal, xc, yc, zc);

				//secondary moving Caustics
				float secScale = _Scale * 0.6;

				worldPos = i.worldPos - distort;

				xc = tex2D(_Tile, float2(worldPos.z, worldPos.y * secScale * 0.25));

				zc = tex2D(_Tile, float2(worldPos.x, worldPos.y * secScale * 0.25));

				yc = tex2D(_Tile, float2(worldPos.y, worldPos.z) * secScale);

				fixed4 causticsTex2 = triplanar(blendNormal, xc, yc, zc);

				causticsTex *= causticsTex2;

				causticsTex *= _Intensity * _ColorT;

				//alpha
				float falloff = tex2Dproj(_FallOffTex, i.uvFalloff).a;

				float alphaMask = tex2Dproj(_Mask, i.uvMask).a;

				float alpha = falloff * alphaMask;

				_Color *= alpha * _Color.a;

				causticsTex *= alpha;

                return causticsTex + _Color;
            }
            ENDCG
        }
    }
}
