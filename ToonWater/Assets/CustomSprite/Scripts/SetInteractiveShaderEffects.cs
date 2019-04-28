using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SetInteractiveShaderEffects : MonoBehaviour {

    [SerializeField]
    private RenderTexture rt;

    [SerializeField]
    private Transform target;

    private void Awake() {
        Shader.SetGlobalTexture("_GlobalEffectRT", rt);

        Shader.SetGlobalFloat("_OrthographicCamSize", GetComponent<Camera>().orthographicSize);
    }

    private void Update() {
        var pos = target.transform.position;

        pos.y = transform.position.y;

        transform.position = pos;

        Shader.SetGlobalVector("_Position", pos);
    }
}
