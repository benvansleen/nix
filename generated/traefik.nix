# This file was generated with nixidy resource generator, do not edit.
{
  lib,
  options,
  config,
  ...
}:

with lib;

let
  hasAttrNotNull = attr: set: hasAttr attr set && set.${attr} != null;

  attrsToList =
    values:
    if values != null then
      sort (
        a: b:
        if (hasAttrNotNull "_priority" a && hasAttrNotNull "_priority" b) then
          a._priority < b._priority
        else
          false
      ) (mapAttrsToList (n: v: v) values)
    else
      values;

  getDefaults =
    resource: group: version: kind:
    catAttrs "default" (
      filter (
        default:
        (default.resource == null || default.resource == resource)
        && (default.group == null || default.group == group)
        && (default.version == null || default.version == version)
        && (default.kind == null || default.kind == kind)
      ) config.defaults
    );

  types = lib.types // rec {
    str = mkOptionType {
      name = "str";
      description = "string";
      check = isString;
      merge = mergeEqualOption;
    };

    # Either value of type `finalType` or `coercedType`, the latter is
    # converted to `finalType` using `coerceFunc`.
    coercedTo =
      coercedType: coerceFunc: finalType:
      mkOptionType rec {
        inherit (finalType) getSubOptions getSubModules;

        name = "coercedTo";
        description = "${finalType.description} or ${coercedType.description}";
        check = x: finalType.check x || coercedType.check x;
        merge =
          loc: defs:
          let
            coerceVal =
              val:
              if finalType.check val then
                val
              else
                let
                  coerced = coerceFunc val;
                in
                assert finalType.check coerced;
                coerced;

          in
          finalType.merge loc (map (def: def // { value = coerceVal def.value; }) defs);
        substSubModules = m: coercedTo coercedType coerceFunc (finalType.substSubModules m);
        typeMerge = t1: t2: null;
        functor = (defaultFunctor name) // {
          wrapped = finalType;
        };
      };
  };

  mkOptionDefault = mkOverride 1001;

  mergeValuesByKey =
    attrMergeKey: listMergeKeys: values:
    listToAttrs (
      imap0 (
        i: value:
        nameValuePair (
          if hasAttr attrMergeKey value then
            if isAttrs value.${attrMergeKey} then
              toString value.${attrMergeKey}.content
            else
              (toString value.${attrMergeKey})
          else
            # generate merge key for list elements if it's not present
            "__kubenix_list_merge_key_"
            + (concatStringsSep "" (
              map (
                key: if isAttrs value.${key} then toString value.${key}.content else (toString value.${key})
              ) listMergeKeys
            ))
        ) (value // { _priority = i; })
      ) values
    );

  submoduleOf =
    ref:
    types.submodule (
      { name, ... }:
      {
        options = definitions."${ref}".options or { };
        config = definitions."${ref}".config or { };
      }
    );

  globalSubmoduleOf =
    ref:
    types.submodule (
      { name, ... }:
      {
        options = config.definitions."${ref}".options or { };
        config = config.definitions."${ref}".config or { };
      }
    );

  submoduleWithMergeOf =
    ref: mergeKey:
    types.submodule (
      { name, ... }:
      let
        convertName =
          name: if definitions."${ref}".options.${mergeKey}.type == types.int then toInt name else name;
      in
      {
        options = definitions."${ref}".options // {
          # position in original array
          _priority = mkOption {
            type = types.nullOr types.int;
            default = null;
            internal = true;
          };
        };
        config = definitions."${ref}".config // {
          ${mergeKey} = mkOverride 1002 (
            # use name as mergeKey only if it is not coming from mergeValuesByKey
            if (!hasPrefix "__kubenix_list_merge_key_" name) then convertName name else null
          );
        };
      }
    );

  submoduleForDefinition =
    ref: resource: kind: group: version:
    let
      apiVersion = if group == "core" then version else "${group}/${version}";
    in
    types.submodule (
      { name, ... }:
      {
        inherit (definitions."${ref}") options;

        imports = getDefaults resource group version kind;
        config = mkMerge [
          definitions."${ref}".config
          {
            kind = mkOptionDefault kind;
            apiVersion = mkOptionDefault apiVersion;

            # metdata.name cannot use option default, due deep config
            metadata.name = mkOptionDefault name;
          }
        ];
      }
    );

  coerceAttrsOfSubmodulesToListByKey =
    ref: attrMergeKey: listMergeKeys:
    (types.coercedTo (types.listOf (submoduleOf ref)) (mergeValuesByKey attrMergeKey listMergeKeys) (
      types.attrsOf (submoduleWithMergeOf ref attrMergeKey)
    ));

  definitions = {
    "gateway.networking.k8s.io.v1.BackendTLSPolicy" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object.\nServers should convert recognized schemas to the latest internal value, and\nmay reject unrecognized values.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = types.nullOr types.str;
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents.\nServers may infer this from the endpoint the client submits requests to.\nCannot be updated.\nIn CamelCase.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = types.nullOr types.str;
        };
        "metadata" = mkOption {
          description = "Standard object's metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = types.nullOr (globalSubmoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta");
        };
        "spec" = mkOption {
          description = "Spec defines the desired state of BackendTLSPolicy.";
          type = submoduleOf "gateway.networking.k8s.io.v1.BackendTLSPolicySpec";
        };
        "status" = mkOption {
          description = "Status defines the current state of BackendTLSPolicy.";
          type = types.nullOr (submoduleOf "gateway.networking.k8s.io.v1.BackendTLSPolicyStatus");
        };
      };

      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1.BackendTLSPolicySpec" = {

      options = {
        "options" = mkOption {
          description = "Options are a list of key/value pairs to enable extended TLS\nconfiguration for each implementation. For example, configuring the\nminimum TLS version or supported cipher suites.\n\nA set of common keys MAY be defined by the API in the future. To avoid\nany ambiguity, implementation-specific definitions MUST use\ndomain-prefixed names, such as `example.com/my-custom-option`.\nUn-prefixed names are reserved for key names defined by Gateway API.\n\nSupport: Implementation-specific";
          type = types.nullOr (types.attrsOf types.str);
        };
        "targetRefs" = mkOption {
          description = "TargetRefs identifies an API object to apply the policy to.\nOnly Services have Extended support. Implementations MAY support\nadditional objects, with Implementation Specific support.\nNote that this config applies to the entire referenced resource\nby default, but this default may change in the future to provide\na more granular application of the policy.\n\nTargetRefs must be _distinct_. This means either that:\n\n* They select different targets. If this is the case, then targetRef\n  entries are distinct. In terms of fields, this means that the\n  multi-part key defined by `group`, `kind`, and `name` must\n  be unique across all targetRef entries in the BackendTLSPolicy.\n* They select different sectionNames in the same target.\n\nWhen more than one BackendTLSPolicy selects the same target and\nsectionName, implementations MUST determine precedence using the\nfollowing criteria, continuing on ties:\n\n* The older policy by creation timestamp takes precedence. For\n  example, a policy with a creation timestamp of \"2021-07-15\n  01:02:03\" MUST be given precedence over a policy with a\n  creation timestamp of \"2021-07-15 01:02:04\".\n* The policy appearing first in alphabetical order by {name}.\n  For example, a policy named `bar` is given precedence over a\n  policy named `baz`.\n\nFor any BackendTLSPolicy that does not take precedence, the\nimplementation MUST ensure the `Accepted` Condition is set to\n`status: False`, with Reason `Conflicted`.\n\nSupport: Extended for Kubernetes Service\n\nSupport: Implementation-specific for any other resource";
          type =
            coerceAttrsOfSubmodulesToListByKey "gateway.networking.k8s.io.v1.BackendTLSPolicySpecTargetRefs"
              "name"
              [ ];
          apply = attrsToList;
        };
        "validation" = mkOption {
          description = "Validation contains backend TLS validation configuration.";
          type = submoduleOf "gateway.networking.k8s.io.v1.BackendTLSPolicySpecValidation";
        };
      };

      config = {
        "options" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1.BackendTLSPolicySpecTargetRefs" = {

      options = {
        "group" = mkOption {
          description = "Group is the group of the target resource.";
          type = types.str;
        };
        "kind" = mkOption {
          description = "Kind is kind of the target resource.";
          type = types.str;
        };
        "name" = mkOption {
          description = "Name is the name of the target resource.";
          type = types.str;
        };
        "sectionName" = mkOption {
          description = "SectionName is the name of a section within the target resource. When\nunspecified, this targetRef targets the entire resource. In the following\nresources, SectionName is interpreted as the following:\n\n* Gateway: Listener name\n* HTTPRoute: HTTPRouteRule name\n* Service: Port name\n\nIf a SectionName is specified, but does not exist on the targeted object,\nthe Policy must fail to attach, and the policy implementation should record\na `ResolvedRefs` or similar Condition in the Policy's status.";
          type = types.nullOr types.str;
        };
      };

      config = {
        "sectionName" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1.BackendTLSPolicySpecValidation" = {

      options = {
        "caCertificateRefs" = mkOption {
          description = "CACertificateRefs contains one or more references to Kubernetes objects that\ncontain a PEM-encoded TLS CA certificate bundle, which is used to\nvalidate a TLS handshake between the Gateway and backend Pod.\n\nIf CACertificateRefs is empty or unspecified, then WellKnownCACertificates must be\nspecified. Only one of CACertificateRefs or WellKnownCACertificates may be specified,\nnot both. If CACertificateRefs is empty or unspecified, the configuration for\nWellKnownCACertificates MUST be honored instead if supported by the implementation.\n\nA CACertificateRef is invalid if:\n\n* It refers to a resource that cannot be resolved (e.g., the referenced resource\n  does not exist) or is misconfigured (e.g., a ConfigMap does not contain a key\n  named `ca.crt`). In this case, the Reason must be set to `InvalidCACertificateRef`\n  and the Message of the Condition must indicate which reference is invalid and why.\n\n* It refers to an unknown or unsupported kind of resource. In this case, the Reason\n  must be set to `InvalidKind` and the Message of the Condition must explain which\n  kind of resource is unknown or unsupported.\n\n* It refers to a resource in another namespace. This may change in future\n  spec updates.\n\nImplementations MAY choose to perform further validation of the certificate\ncontent (e.g., checking expiry or enforcing specific formats). In such cases,\nan implementation-specific Reason and Message must be set for the invalid reference.\n\nIn all cases, the implementation MUST ensure the `ResolvedRefs` Condition on\nthe BackendTLSPolicy is set to `status: False`, with a Reason and Message\nthat indicate the cause of the error. Connections using an invalid\nCACertificateRef MUST fail, and the client MUST receive an HTTP 5xx error\nresponse. If ALL CACertificateRefs are invalid, the implementation MUST also\nensure the `Accepted` Condition on the BackendTLSPolicy is set to\n`status: False`, with a Reason `NoValidCACertificate`.\n\nA single CACertificateRef to a Kubernetes ConfigMap kind has \"Core\" support.\nImplementations MAY choose to support attaching multiple certificates to\na backend, but this behavior is implementation-specific.\n\nSupport: Core - An optional single reference to a Kubernetes ConfigMap,\nwith the CA certificate in a key named `ca.crt`.\n\nSupport: Implementation-specific - More than one reference, other kinds\nof resources, or a single reference that includes multiple certificates.";
          type = types.nullOr (
            coerceAttrsOfSubmodulesToListByKey
              "gateway.networking.k8s.io.v1.BackendTLSPolicySpecValidationCaCertificateRefs"
              "name"
              [ ]
          );
          apply = attrsToList;
        };
        "hostname" = mkOption {
          description = "Hostname is used for two purposes in the connection between Gateways and\nbackends:\n\n1. Hostname MUST be used as the SNI to connect to the backend (RFC 6066).\n2. Hostname MUST be used for authentication and MUST match the certificate\n   served by the matching backend, unless SubjectAltNames is specified.\n3. If SubjectAltNames are specified, Hostname can be used for certificate selection\n   but MUST NOT be used for authentication. If you want to use the value\n   of the Hostname field for authentication, you MUST add it to the SubjectAltNames list.\n\nSupport: Core";
          type = types.str;
        };
        "subjectAltNames" = mkOption {
          description = "SubjectAltNames contains one or more Subject Alternative Names.\nWhen specified the certificate served from the backend MUST\nhave at least one Subject Alternate Name matching one of the specified SubjectAltNames.\n\nSupport: Extended";
          type = types.nullOr (
            types.listOf (
              submoduleOf "gateway.networking.k8s.io.v1.BackendTLSPolicySpecValidationSubjectAltNames"
            )
          );
        };
        "wellKnownCACertificates" = mkOption {
          description = "WellKnownCACertificates specifies whether system CA certificates may be used in\nthe TLS handshake between the gateway and backend pod.\n\nIf WellKnownCACertificates is unspecified or empty (\"\"), then CACertificateRefs\nmust be specified with at least one entry for a valid configuration. Only one of\nCACertificateRefs or WellKnownCACertificates may be specified, not both.\nIf an implementation does not support the WellKnownCACertificates field, or\nthe supplied value is not recognized, the implementation MUST ensure the\n`Accepted` Condition on the BackendTLSPolicy is set to `status: False`, with\na Reason `Invalid`.\n\nSupport: Implementation-specific";
          type = types.nullOr types.str;
        };
      };

      config = {
        "caCertificateRefs" = mkOverride 1002 null;
        "subjectAltNames" = mkOverride 1002 null;
        "wellKnownCACertificates" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1.BackendTLSPolicySpecValidationCaCertificateRefs" = {

      options = {
        "group" = mkOption {
          description = "Group is the group of the referent. For example, \"gateway.networking.k8s.io\".\nWhen unspecified or empty string, core API group is inferred.";
          type = types.str;
        };
        "kind" = mkOption {
          description = "Kind is kind of the referent. For example \"HTTPRoute\" or \"Service\".";
          type = types.str;
        };
        "name" = mkOption {
          description = "Name is the name of the referent.";
          type = types.str;
        };
      };

      config = { };

    };
    "gateway.networking.k8s.io.v1.BackendTLSPolicySpecValidationSubjectAltNames" = {

      options = {
        "hostname" = mkOption {
          description = "Hostname contains Subject Alternative Name specified in DNS name format.\nRequired when Type is set to Hostname, ignored otherwise.\n\nSupport: Core";
          type = types.nullOr types.str;
        };
        "type" = mkOption {
          description = "Type determines the format of the Subject Alternative Name. Always required.\n\nSupport: Core";
          type = types.str;
        };
        "uri" = mkOption {
          description = "URI contains Subject Alternative Name specified in a full URI format.\nIt MUST include both a scheme (e.g., \"http\" or \"ftp\") and a scheme-specific-part.\nCommon values include SPIFFE IDs like \"spiffe://mycluster.example.com/ns/myns/sa/svc1sa\".\nRequired when Type is set to URI, ignored otherwise.\n\nSupport: Core";
          type = types.nullOr types.str;
        };
      };

      config = {
        "hostname" = mkOverride 1002 null;
        "uri" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1.BackendTLSPolicyStatus" = {

      options = {
        "ancestors" = mkOption {
          description = "Ancestors is a list of ancestor resources (usually Gateways) that are\nassociated with the policy, and the status of the policy with respect to\neach ancestor. When this policy attaches to a parent, the controller that\nmanages the parent and the ancestors MUST add an entry to this list when\nthe controller first sees the policy and SHOULD update the entry as\nappropriate when the relevant ancestor is modified.\n\nNote that choosing the relevant ancestor is left to the Policy designers;\nan important part of Policy design is designing the right object level at\nwhich to namespace this status.\n\nNote also that implementations MUST ONLY populate ancestor status for\nthe Ancestor resources they are responsible for. Implementations MUST\nuse the ControllerName field to uniquely identify the entries in this list\nthat they are responsible for.\n\nNote that to achieve this, the list of PolicyAncestorStatus structs\nMUST be treated as a map with a composite key, made up of the AncestorRef\nand ControllerName fields combined.\n\nA maximum of 16 ancestors will be represented in this list. An empty list\nmeans the Policy is not relevant for any ancestors.\n\nIf this slice is full, implementations MUST NOT add further entries.\nInstead they MUST consider the policy unimplementable and signal that\non any related resources such as the ancestor that would be referenced\nhere. For example, if this list was full on BackendTLSPolicy, no\nadditional Gateways would be able to reference the Service targeted by\nthe BackendTLSPolicy.";
          type = types.listOf (submoduleOf "gateway.networking.k8s.io.v1.BackendTLSPolicyStatusAncestors");
        };
      };

      config = { };

    };
    "gateway.networking.k8s.io.v1.BackendTLSPolicyStatusAncestors" = {

      options = {
        "ancestorRef" = mkOption {
          description = "AncestorRef corresponds with a ParentRef in the spec that this\nPolicyAncestorStatus struct describes the status of.";
          type = submoduleOf "gateway.networking.k8s.io.v1.BackendTLSPolicyStatusAncestorsAncestorRef";
        };
        "conditions" = mkOption {
          description = "Conditions describes the status of the Policy with respect to the given Ancestor.";
          type = types.listOf (
            submoduleOf "gateway.networking.k8s.io.v1.BackendTLSPolicyStatusAncestorsConditions"
          );
        };
        "controllerName" = mkOption {
          description = "ControllerName is a domain/path string that indicates the name of the\ncontroller that wrote this status. This corresponds with the\ncontrollerName field on GatewayClass.\n\nExample: \"example.net/gateway-controller\".\n\nThe format of this field is DOMAIN \"/\" PATH, where DOMAIN and PATH are\nvalid Kubernetes names\n(https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names).\n\nControllers MUST populate this field when writing status. Controllers should ensure that\nentries to status populated with their ControllerName are cleaned up when they are no\nlonger necessary.";
          type = types.str;
        };
      };

      config = { };

    };
    "gateway.networking.k8s.io.v1.BackendTLSPolicyStatusAncestorsAncestorRef" = {

      options = {
        "group" = mkOption {
          description = "Group is the group of the referent.\nWhen unspecified, \"gateway.networking.k8s.io\" is inferred.\nTo set the core API group (such as for a \"Service\" kind referent),\nGroup must be explicitly set to \"\" (empty string).\n\nSupport: Core";
          type = types.nullOr types.str;
        };
        "kind" = mkOption {
          description = "Kind is kind of the referent.\n\nThere are two kinds of parent resources with \"Core\" support:\n\n* Gateway (Gateway conformance profile)\n* Service (Mesh conformance profile, ClusterIP Services only)\n\nSupport for other resources is Implementation-Specific.";
          type = types.nullOr types.str;
        };
        "name" = mkOption {
          description = "Name is the name of the referent.\n\nSupport: Core";
          type = types.str;
        };
        "namespace" = mkOption {
          description = "Namespace is the namespace of the referent. When unspecified, this refers\nto the local namespace of the Route.\n\nNote that there are specific rules for ParentRefs which cross namespace\nboundaries. Cross-namespace references are only valid if they are explicitly\nallowed by something in the namespace they are referring to. For example:\nGateway has the AllowedRoutes field, and ReferenceGrant provides a\ngeneric way to enable any other kind of cross-namespace reference.\n\nSupport: Core";
          type = types.nullOr types.str;
        };
        "port" = mkOption {
          description = "Port is the network port this Route targets. It can be interpreted\ndifferently based on the type of parent resource.\n\nWhen the parent resource is a Gateway, this targets all listeners\nlistening on the specified port that also support this kind of Route(and\nselect this Route). It's not recommended to set `Port` unless the\nnetworking behaviors specified in a Route must apply to a specific port\nas opposed to a listener(s) whose port(s) may be changed. When both Port\nand SectionName are specified, the name and port of the selected listener\nmust match both specified values.\n\nImplementations MAY choose to support other parent resources.\nImplementations supporting other types of parent resources MUST clearly\ndocument how/if Port is interpreted.\n\nFor the purpose of status, an attachment is considered successful as\nlong as the parent resource accepts it partially. For example, Gateway\nlisteners can restrict which Routes can attach to them by Route kind,\nnamespace, or hostname. If 1 of 2 Gateway listeners accept attachment\nfrom the referencing Route, the Route MUST be considered successfully\nattached. If no Gateway listeners accept attachment from this Route,\nthe Route MUST be considered detached from the Gateway.\n\nSupport: Extended";
          type = types.nullOr types.int;
        };
        "sectionName" = mkOption {
          description = "SectionName is the name of a section within the target resource. In the\nfollowing resources, SectionName is interpreted as the following:\n\n* Gateway: Listener name. When both Port (experimental) and SectionName\nare specified, the name and port of the selected listener must match\nboth specified values.\n* Service: Port name. When both Port (experimental) and SectionName\nare specified, the name and port of the selected listener must match\nboth specified values.\n\nImplementations MAY choose to support attaching Routes to other resources.\nIf that is the case, they MUST clearly document how SectionName is\ninterpreted.\n\nWhen unspecified (empty string), this will reference the entire resource.\nFor the purpose of status, an attachment is considered successful if at\nleast one section in the parent resource accepts it. For example, Gateway\nlisteners can restrict which Routes can attach to them by Route kind,\nnamespace, or hostname. If 1 of 2 Gateway listeners accept attachment from\nthe referencing Route, the Route MUST be considered successfully\nattached. If no Gateway listeners accept attachment from this Route, the\nRoute MUST be considered detached from the Gateway.\n\nSupport: Core";
          type = types.nullOr types.str;
        };
      };

      config = {
        "group" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
        "port" = mkOverride 1002 null;
        "sectionName" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1.BackendTLSPolicyStatusAncestorsConditions" = {

      options = {
        "lastTransitionTime" = mkOption {
          description = "lastTransitionTime is the last time the condition transitioned from one status to another.\nThis should be when the underlying condition changed.  If that is not known, then using the time when the API field changed is acceptable.";
          type = types.str;
        };
        "message" = mkOption {
          description = "message is a human readable message indicating details about the transition.\nThis may be an empty string.";
          type = types.str;
        };
        "observedGeneration" = mkOption {
          description = "observedGeneration represents the .metadata.generation that the condition was set based upon.\nFor instance, if .metadata.generation is currently 12, but the .status.conditions[x].observedGeneration is 9, the condition is out of date\nwith respect to the current state of the instance.";
          type = types.nullOr types.int;
        };
        "reason" = mkOption {
          description = "reason contains a programmatic identifier indicating the reason for the condition's last transition.\nProducers of specific condition types may define expected values and meanings for this field,\nand whether the values are considered a guaranteed API.\nThe value should be a CamelCase string.\nThis field may not be empty.";
          type = types.str;
        };
        "status" = mkOption {
          description = "status of the condition, one of True, False, Unknown.";
          type = types.str;
        };
        "type" = mkOption {
          description = "type of condition in CamelCase or in foo.example.com/CamelCase.";
          type = types.str;
        };
      };

      config = {
        "observedGeneration" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1.GRPCRoute" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object.\nServers should convert recognized schemas to the latest internal value, and\nmay reject unrecognized values.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = types.nullOr types.str;
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents.\nServers may infer this from the endpoint the client submits requests to.\nCannot be updated.\nIn CamelCase.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = types.nullOr types.str;
        };
        "metadata" = mkOption {
          description = "Standard object's metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = types.nullOr (globalSubmoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta");
        };
        "spec" = mkOption {
          description = "Spec defines the desired state of GRPCRoute.";
          type = submoduleOf "gateway.networking.k8s.io.v1.GRPCRouteSpec";
        };
        "status" = mkOption {
          description = "Status defines the current state of GRPCRoute.";
          type = types.nullOr (submoduleOf "gateway.networking.k8s.io.v1.GRPCRouteStatus");
        };
      };

      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1.GRPCRouteSpec" = {

      options = {
        "hostnames" = mkOption {
          description = "Hostnames defines a set of hostnames to match against the GRPC\nHost header to select a GRPCRoute to process the request. This matches\nthe RFC 1123 definition of a hostname with 2 notable exceptions:\n\n1. IPs are not allowed.\n2. A hostname may be prefixed with a wildcard label (`*.`). The wildcard\n   label MUST appear by itself as the first label.\n\nIf a hostname is specified by both the Listener and GRPCRoute, there\nMUST be at least one intersecting hostname for the GRPCRoute to be\nattached to the Listener. For example:\n\n* A Listener with `test.example.com` as the hostname matches GRPCRoutes\n  that have either not specified any hostnames, or have specified at\n  least one of `test.example.com` or `*.example.com`.\n* A Listener with `*.example.com` as the hostname matches GRPCRoutes\n  that have either not specified any hostnames or have specified at least\n  one hostname that matches the Listener hostname. For example,\n  `test.example.com` and `*.example.com` would both match. On the other\n  hand, `example.com` and `test.example.net` would not match.\n\nHostnames that are prefixed with a wildcard label (`*.`) are interpreted\nas a suffix match. That means that a match for `*.example.com` would match\nboth `test.example.com`, and `foo.test.example.com`, but not `example.com`.\n\nIf both the Listener and GRPCRoute have specified hostnames, any\nGRPCRoute hostnames that do not match the Listener hostname MUST be\nignored. For example, if a Listener specified `*.example.com`, and the\nGRPCRoute specified `test.example.com` and `test.example.net`,\n`test.example.net` MUST NOT be considered for a match.\n\nIf both the Listener and GRPCRoute have specified hostnames, and none\nmatch with the criteria above, then the GRPCRoute MUST NOT be accepted by\nthe implementation. The implementation MUST raise an 'Accepted' Condition\nwith a status of `False` in the corresponding RouteParentStatus.\n\nIf a Route (A) of type HTTPRoute or GRPCRoute is attached to a\nListener and that listener already has another Route (B) of the other\ntype attached and the intersection of the hostnames of A and B is\nnon-empty, then the implementation MUST accept exactly one of these two\nroutes, determined by the following criteria, in order:\n\n* The oldest Route based on creation timestamp.\n* The Route appearing first in alphabetical order by\n  \"{namespace}/{name}\".\n\nThe rejected Route MUST raise an 'Accepted' condition with a status of\n'False' in the corresponding RouteParentStatus.\n\nSupport: Core";
          type = types.nullOr (types.listOf types.str);
        };
        "parentRefs" = mkOption {
          description = "ParentRefs references the resources (usually Gateways) that a Route wants\nto be attached to. Note that the referenced parent resource needs to\nallow this for the attachment to be complete. For Gateways, that means\nthe Gateway needs to allow attachment from Routes of this kind and\nnamespace. For Services, that means the Service must either be in the same\nnamespace for a \"producer\" route, or the mesh implementation must support\nand allow \"consumer\" routes for the referenced Service. ReferenceGrant is\nnot applicable for governing ParentRefs to Services - it is not possible to\ncreate a \"producer\" route for a Service in a different namespace from the\nRoute.\n\nThere are two kinds of parent resources with \"Core\" support:\n\n* Gateway (Gateway conformance profile)\n* Service (Mesh conformance profile, ClusterIP Services only)\n\nThis API may be extended in the future to support additional kinds of parent\nresources.\n\nParentRefs must be _distinct_. This means either that:\n\n* They select different objects.  If this is the case, then parentRef\n  entries are distinct. In terms of fields, this means that the\n  multi-part key defined by `group`, `kind`, `namespace`, and `name` must\n  be unique across all parentRef entries in the Route.\n* They do not select different objects, but for each optional field used,\n  each ParentRef that selects the same object must set the same set of\n  optional fields to different values. If one ParentRef sets a\n  combination of optional fields, all must set the same combination.\n\nSome examples:\n\n* If one ParentRef sets `sectionName`, all ParentRefs referencing the\n  same object must also set `sectionName`.\n* If one ParentRef sets `port`, all ParentRefs referencing the same\n  object must also set `port`.\n* If one ParentRef sets `sectionName` and `port`, all ParentRefs\n  referencing the same object must also set `sectionName` and `port`.\n\nIt is possible to separately reference multiple distinct objects that may\nbe collapsed by an implementation. For example, some implementations may\nchoose to merge compatible Gateway Listeners together. If that is the\ncase, the list of routes attached to those resources should also be\nmerged.\n\nNote that for ParentRefs that cross namespace boundaries, there are specific\nrules. Cross-namespace references are only valid if they are explicitly\nallowed by something in the namespace they are referring to. For example,\nGateway has the AllowedRoutes field, and ReferenceGrant provides a\ngeneric way to enable other kinds of cross-namespace reference.";
          type = types.nullOr (
            coerceAttrsOfSubmodulesToListByKey "gateway.networking.k8s.io.v1.GRPCRouteSpecParentRefs" "name" [ ]
          );
          apply = attrsToList;
        };
        "rules" = mkOption {
          description = "Rules are a list of GRPC matchers, filters and actions.";
          type = types.nullOr (
            coerceAttrsOfSubmodulesToListByKey "gateway.networking.k8s.io.v1.GRPCRouteSpecRules" "name" [ ]
          );
          apply = attrsToList;
        };
      };

      config = {
        "hostnames" = mkOverride 1002 null;
        "parentRefs" = mkOverride 1002 null;
        "rules" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1.GRPCRouteSpecParentRefs" = {

      options = {
        "group" = mkOption {
          description = "Group is the group of the referent.\nWhen unspecified, \"gateway.networking.k8s.io\" is inferred.\nTo set the core API group (such as for a \"Service\" kind referent),\nGroup must be explicitly set to \"\" (empty string).\n\nSupport: Core";
          type = types.nullOr types.str;
        };
        "kind" = mkOption {
          description = "Kind is kind of the referent.\n\nThere are two kinds of parent resources with \"Core\" support:\n\n* Gateway (Gateway conformance profile)\n* Service (Mesh conformance profile, ClusterIP Services only)\n\nSupport for other resources is Implementation-Specific.";
          type = types.nullOr types.str;
        };
        "name" = mkOption {
          description = "Name is the name of the referent.\n\nSupport: Core";
          type = types.str;
        };
        "namespace" = mkOption {
          description = "Namespace is the namespace of the referent. When unspecified, this refers\nto the local namespace of the Route.\n\nNote that there are specific rules for ParentRefs which cross namespace\nboundaries. Cross-namespace references are only valid if they are explicitly\nallowed by something in the namespace they are referring to. For example:\nGateway has the AllowedRoutes field, and ReferenceGrant provides a\ngeneric way to enable any other kind of cross-namespace reference.\n\nSupport: Core";
          type = types.nullOr types.str;
        };
        "port" = mkOption {
          description = "Port is the network port this Route targets. It can be interpreted\ndifferently based on the type of parent resource.\n\nWhen the parent resource is a Gateway, this targets all listeners\nlistening on the specified port that also support this kind of Route(and\nselect this Route). It's not recommended to set `Port` unless the\nnetworking behaviors specified in a Route must apply to a specific port\nas opposed to a listener(s) whose port(s) may be changed. When both Port\nand SectionName are specified, the name and port of the selected listener\nmust match both specified values.\n\nImplementations MAY choose to support other parent resources.\nImplementations supporting other types of parent resources MUST clearly\ndocument how/if Port is interpreted.\n\nFor the purpose of status, an attachment is considered successful as\nlong as the parent resource accepts it partially. For example, Gateway\nlisteners can restrict which Routes can attach to them by Route kind,\nnamespace, or hostname. If 1 of 2 Gateway listeners accept attachment\nfrom the referencing Route, the Route MUST be considered successfully\nattached. If no Gateway listeners accept attachment from this Route,\nthe Route MUST be considered detached from the Gateway.\n\nSupport: Extended";
          type = types.nullOr types.int;
        };
        "sectionName" = mkOption {
          description = "SectionName is the name of a section within the target resource. In the\nfollowing resources, SectionName is interpreted as the following:\n\n* Gateway: Listener name. When both Port (experimental) and SectionName\nare specified, the name and port of the selected listener must match\nboth specified values.\n* Service: Port name. When both Port (experimental) and SectionName\nare specified, the name and port of the selected listener must match\nboth specified values.\n\nImplementations MAY choose to support attaching Routes to other resources.\nIf that is the case, they MUST clearly document how SectionName is\ninterpreted.\n\nWhen unspecified (empty string), this will reference the entire resource.\nFor the purpose of status, an attachment is considered successful if at\nleast one section in the parent resource accepts it. For example, Gateway\nlisteners can restrict which Routes can attach to them by Route kind,\nnamespace, or hostname. If 1 of 2 Gateway listeners accept attachment from\nthe referencing Route, the Route MUST be considered successfully\nattached. If no Gateway listeners accept attachment from this Route, the\nRoute MUST be considered detached from the Gateway.\n\nSupport: Core";
          type = types.nullOr types.str;
        };
      };

      config = {
        "group" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
        "port" = mkOverride 1002 null;
        "sectionName" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1.GRPCRouteSpecRules" = {

      options = {
        "backendRefs" = mkOption {
          description = "BackendRefs defines the backend(s) where matching requests should be\nsent.\n\nFailure behavior here depends on how many BackendRefs are specified and\nhow many are invalid.\n\nIf *all* entries in BackendRefs are invalid, and there are also no filters\nspecified in this route rule, *all* traffic which matches this rule MUST\nreceive an `UNAVAILABLE` status.\n\nSee the GRPCBackendRef definition for the rules about what makes a single\nGRPCBackendRef invalid.\n\nWhen a GRPCBackendRef is invalid, `UNAVAILABLE` statuses MUST be returned for\nrequests that would have otherwise been routed to an invalid backend. If\nmultiple backends are specified, and some are invalid, the proportion of\nrequests that would otherwise have been routed to an invalid backend\nMUST receive an `UNAVAILABLE` status.\n\nFor example, if two backends are specified with equal weights, and one is\ninvalid, 50 percent of traffic MUST receive an `UNAVAILABLE` status.\nImplementations may choose how that 50 percent is determined.\n\nSupport: Core for Kubernetes Service\n\nSupport: Implementation-specific for any other resource\n\nSupport for weight: Core";
          type = types.nullOr (
            coerceAttrsOfSubmodulesToListByKey "gateway.networking.k8s.io.v1.GRPCRouteSpecRulesBackendRefs"
              "name"
              [ ]
          );
          apply = attrsToList;
        };
        "filters" = mkOption {
          description = "Filters define the filters that are applied to requests that match\nthis rule.\n\nThe effects of ordering of multiple behaviors are currently unspecified.\nThis can change in the future based on feedback during the alpha stage.\n\nConformance-levels at this level are defined based on the type of filter:\n\n- ALL core filters MUST be supported by all implementations that support\n  GRPCRoute.\n- Implementers are encouraged to support extended filters.\n- Implementation-specific custom filters have no API guarantees across\n  implementations.\n\nSpecifying the same filter multiple times is not supported unless explicitly\nindicated in the filter.\n\nIf an implementation cannot support a combination of filters, it must clearly\ndocument that limitation. In cases where incompatible or unsupported\nfilters are specified and cause the `Accepted` condition to be set to status\n`False`, implementations may use the `IncompatibleFilters` reason to specify\nthis configuration error.\n\nSupport: Core";
          type = types.nullOr (
            types.listOf (submoduleOf "gateway.networking.k8s.io.v1.GRPCRouteSpecRulesFilters")
          );
        };
        "matches" = mkOption {
          description = "Matches define conditions used for matching the rule against incoming\ngRPC requests. Each match is independent, i.e. this rule will be matched\nif **any** one of the matches is satisfied.\n\nFor example, take the following matches configuration:\n\n```\nmatches:\n- method:\n    service: foo.bar\n  headers:\n    values:\n      version: 2\n- method:\n    service: foo.bar.v2\n```\n\nFor a request to match against this rule, it MUST satisfy\nEITHER of the two conditions:\n\n- service of foo.bar AND contains the header `version: 2`\n- service of foo.bar.v2\n\nSee the documentation for GRPCRouteMatch on how to specify multiple\nmatch conditions to be ANDed together.\n\nIf no matches are specified, the implementation MUST match every gRPC request.\n\nProxy or Load Balancer routing configuration generated from GRPCRoutes\nMUST prioritize rules based on the following criteria, continuing on\nties. Merging MUST not be done between GRPCRoutes and HTTPRoutes.\nPrecedence MUST be given to the rule with the largest number of:\n\n* Characters in a matching non-wildcard hostname.\n* Characters in a matching hostname.\n* Characters in a matching service.\n* Characters in a matching method.\n* Header matches.\n\nIf ties still exist across multiple Routes, matching precedence MUST be\ndetermined in order of the following criteria, continuing on ties:\n\n* The oldest Route based on creation timestamp.\n* The Route appearing first in alphabetical order by\n  \"{namespace}/{name}\".\n\nIf ties still exist within the Route that has been given precedence,\nmatching precedence MUST be granted to the first matching rule meeting\nthe above criteria.";
          type = types.nullOr (
            types.listOf (submoduleOf "gateway.networking.k8s.io.v1.GRPCRouteSpecRulesMatches")
          );
        };
        "name" = mkOption {
          description = "Name is the name of the route rule. This name MUST be unique within a Route if it is set.\n\nSupport: Extended";
          type = types.nullOr types.str;
        };
      };

      config = {
        "backendRefs" = mkOverride 1002 null;
        "filters" = mkOverride 1002 null;
        "matches" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1.GRPCRouteSpecRulesBackendRefs" = {

      options = {
        "filters" = mkOption {
          description = "Filters defined at this level MUST be executed if and only if the\nrequest is being forwarded to the backend defined here.\n\nSupport: Implementation-specific (For broader support of filters, use the\nFilters field in GRPCRouteRule.)";
          type = types.nullOr (
            types.listOf (submoduleOf "gateway.networking.k8s.io.v1.GRPCRouteSpecRulesBackendRefsFilters")
          );
        };
        "group" = mkOption {
          description = "Group is the group of the referent. For example, \"gateway.networking.k8s.io\".\nWhen unspecified or empty string, core API group is inferred.";
          type = types.nullOr types.str;
        };
        "kind" = mkOption {
          description = "Kind is the Kubernetes resource kind of the referent. For example\n\"Service\".\n\nDefaults to \"Service\" when not specified.\n\nExternalName services can refer to CNAME DNS records that may live\noutside of the cluster and as such are difficult to reason about in\nterms of conformance. They also may not be safe to forward to (see\nCVE-2021-25740 for more information). Implementations SHOULD NOT\nsupport ExternalName Services.\n\nSupport: Core (Services with a type other than ExternalName)\n\nSupport: Implementation-specific (Services with type ExternalName)";
          type = types.nullOr types.str;
        };
        "name" = mkOption {
          description = "Name is the name of the referent.";
          type = types.str;
        };
        "namespace" = mkOption {
          description = "Namespace is the namespace of the backend. When unspecified, the local\nnamespace is inferred.\n\nNote that when a namespace different than the local namespace is specified,\na ReferenceGrant object is required in the referent namespace to allow that\nnamespace's owner to accept the reference. See the ReferenceGrant\ndocumentation for details.\n\nSupport: Core";
          type = types.nullOr types.str;
        };
        "port" = mkOption {
          description = "Port specifies the destination port number to use for this resource.\nPort is required when the referent is a Kubernetes Service. In this\ncase, the port number is the service port number, not the target port.\nFor other resources, destination port might be derived from the referent\nresource or this field.";
          type = types.nullOr types.int;
        };
        "weight" = mkOption {
          description = "Weight specifies the proportion of requests forwarded to the referenced\nbackend. This is computed as weight/(sum of all weights in this\nBackendRefs list). For non-zero values, there may be some epsilon from\nthe exact proportion defined here depending on the precision an\nimplementation supports. Weight is not a percentage and the sum of\nweights does not need to equal 100.\n\nIf only one backend is specified and it has a weight greater than 0, 100%\nof the traffic is forwarded to that backend. If weight is set to 0, no\ntraffic should be forwarded for this entry. If unspecified, weight\ndefaults to 1.\n\nSupport for this field varies based on the context where used.";
          type = types.nullOr types.int;
        };
      };

      config = {
        "filters" = mkOverride 1002 null;
        "group" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
        "port" = mkOverride 1002 null;
        "weight" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1.GRPCRouteSpecRulesBackendRefsFilters" = {

      options = {
        "extensionRef" = mkOption {
          description = "ExtensionRef is an optional, implementation-specific extension to the\n\"filter\" behavior.  For example, resource \"myroutefilter\" in group\n\"networking.example.net\"). ExtensionRef MUST NOT be used for core and\nextended filters.\n\nSupport: Implementation-specific\n\nThis filter can be used multiple times within the same rule.";
          type = types.nullOr (
            submoduleOf "gateway.networking.k8s.io.v1.GRPCRouteSpecRulesBackendRefsFiltersExtensionRef"
          );
        };
        "requestHeaderModifier" = mkOption {
          description = "RequestHeaderModifier defines a schema for a filter that modifies request\nheaders.\n\nSupport: Core";
          type = types.nullOr (
            submoduleOf "gateway.networking.k8s.io.v1.GRPCRouteSpecRulesBackendRefsFiltersRequestHeaderModifier"
          );
        };
        "requestMirror" = mkOption {
          description = "RequestMirror defines a schema for a filter that mirrors requests.\nRequests are sent to the specified destination, but responses from\nthat destination are ignored.\n\nThis filter can be used multiple times within the same rule. Note that\nnot all implementations will be able to support mirroring to multiple\nbackends.\n\nSupport: Extended";
          type = types.nullOr (
            submoduleOf "gateway.networking.k8s.io.v1.GRPCRouteSpecRulesBackendRefsFiltersRequestMirror"
          );
        };
        "responseHeaderModifier" = mkOption {
          description = "ResponseHeaderModifier defines a schema for a filter that modifies response\nheaders.\n\nSupport: Extended";
          type = types.nullOr (
            submoduleOf "gateway.networking.k8s.io.v1.GRPCRouteSpecRulesBackendRefsFiltersResponseHeaderModifier"
          );
        };
        "type" = mkOption {
          description = "Type identifies the type of filter to apply. As with other API fields,\ntypes are classified into three conformance levels:\n\n- Core: Filter types and their corresponding configuration defined by\n  \"Support: Core\" in this package, e.g. \"RequestHeaderModifier\". All\n  implementations supporting GRPCRoute MUST support core filters.\n\n- Extended: Filter types and their corresponding configuration defined by\n  \"Support: Extended\" in this package, e.g. \"RequestMirror\". Implementers\n  are encouraged to support extended filters.\n\n- Implementation-specific: Filters that are defined and supported by specific vendors.\n  In the future, filters showing convergence in behavior across multiple\n  implementations will be considered for inclusion in extended or core\n  conformance levels. Filter-specific configuration for such filters\n  is specified using the ExtensionRef field. `Type` MUST be set to\n  \"ExtensionRef\" for custom filters.\n\nImplementers are encouraged to define custom implementation types to\nextend the core API with implementation-specific behavior.\n\nIf a reference to a custom filter type cannot be resolved, the filter\nMUST NOT be skipped. Instead, requests that would have been processed by\nthat filter MUST receive a HTTP error response.";
          type = types.str;
        };
      };

      config = {
        "extensionRef" = mkOverride 1002 null;
        "requestHeaderModifier" = mkOverride 1002 null;
        "requestMirror" = mkOverride 1002 null;
        "responseHeaderModifier" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1.GRPCRouteSpecRulesBackendRefsFiltersExtensionRef" = {

      options = {
        "group" = mkOption {
          description = "Group is the group of the referent. For example, \"gateway.networking.k8s.io\".\nWhen unspecified or empty string, core API group is inferred.";
          type = types.str;
        };
        "kind" = mkOption {
          description = "Kind is kind of the referent. For example \"HTTPRoute\" or \"Service\".";
          type = types.str;
        };
        "name" = mkOption {
          description = "Name is the name of the referent.";
          type = types.str;
        };
      };

      config = { };

    };
    "gateway.networking.k8s.io.v1.GRPCRouteSpecRulesBackendRefsFiltersRequestHeaderModifier" = {

      options = {
        "add" = mkOption {
          description = "Add adds the given header(s) (name, value) to the request\nbefore the action. It appends to any existing values associated\nwith the header name.\n\nInput:\n  GET /foo HTTP/1.1\n  my-header: foo\n\nConfig:\n  add:\n  - name: \"my-header\"\n    value: \"bar,baz\"\n\nOutput:\n  GET /foo HTTP/1.1\n  my-header: foo,bar,baz";
          type = types.nullOr (
            coerceAttrsOfSubmodulesToListByKey
              "gateway.networking.k8s.io.v1.GRPCRouteSpecRulesBackendRefsFiltersRequestHeaderModifierAdd"
              "name"
              [ "name" ]
          );
          apply = attrsToList;
        };
        "remove" = mkOption {
          description = "Remove the given header(s) from the HTTP request before the action. The\nvalue of Remove is a list of HTTP header names. Note that the header\nnames are case-insensitive (see\nhttps://datatracker.ietf.org/doc/html/rfc2616#section-4.2).\n\nInput:\n  GET /foo HTTP/1.1\n  my-header1: foo\n  my-header2: bar\n  my-header3: baz\n\nConfig:\n  remove: [\"my-header1\", \"my-header3\"]\n\nOutput:\n  GET /foo HTTP/1.1\n  my-header2: bar";
          type = types.nullOr (types.listOf types.str);
        };
        "set" = mkOption {
          description = "Set overwrites the request with the given header (name, value)\nbefore the action.\n\nInput:\n  GET /foo HTTP/1.1\n  my-header: foo\n\nConfig:\n  set:\n  - name: \"my-header\"\n    value: \"bar\"\n\nOutput:\n  GET /foo HTTP/1.1\n  my-header: bar";
          type = types.nullOr (
            coerceAttrsOfSubmodulesToListByKey
              "gateway.networking.k8s.io.v1.GRPCRouteSpecRulesBackendRefsFiltersRequestHeaderModifierSet"
              "name"
              [ "name" ]
          );
          apply = attrsToList;
        };
      };

      config = {
        "add" = mkOverride 1002 null;
        "remove" = mkOverride 1002 null;
        "set" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1.GRPCRouteSpecRulesBackendRefsFiltersRequestHeaderModifierAdd" = {

      options = {
        "name" = mkOption {
          description = "Name is the name of the HTTP Header to be matched. Name matching MUST be\ncase-insensitive. (See https://tools.ietf.org/html/rfc7230#section-3.2).\n\nIf multiple entries specify equivalent header names, the first entry with\nan equivalent name MUST be considered for a match. Subsequent entries\nwith an equivalent header name MUST be ignored. Due to the\ncase-insensitivity of header names, \"foo\" and \"Foo\" are considered\nequivalent.";
          type = types.str;
        };
        "value" = mkOption {
          description = "Value is the value of HTTP Header to be matched.";
          type = types.str;
        };
      };

      config = { };

    };
    "gateway.networking.k8s.io.v1.GRPCRouteSpecRulesBackendRefsFiltersRequestHeaderModifierSet" = {

      options = {
        "name" = mkOption {
          description = "Name is the name of the HTTP Header to be matched. Name matching MUST be\ncase-insensitive. (See https://tools.ietf.org/html/rfc7230#section-3.2).\n\nIf multiple entries specify equivalent header names, the first entry with\nan equivalent name MUST be considered for a match. Subsequent entries\nwith an equivalent header name MUST be ignored. Due to the\ncase-insensitivity of header names, \"foo\" and \"Foo\" are considered\nequivalent.";
          type = types.str;
        };
        "value" = mkOption {
          description = "Value is the value of HTTP Header to be matched.";
          type = types.str;
        };
      };

      config = { };

    };
    "gateway.networking.k8s.io.v1.GRPCRouteSpecRulesBackendRefsFiltersRequestMirror" = {

      options = {
        "backendRef" = mkOption {
          description = "BackendRef references a resource where mirrored requests are sent.\n\nMirrored requests must be sent only to a single destination endpoint\nwithin this BackendRef, irrespective of how many endpoints are present\nwithin this BackendRef.\n\nIf the referent cannot be found, this BackendRef is invalid and must be\ndropped from the Gateway. The controller must ensure the \"ResolvedRefs\"\ncondition on the Route status is set to `status: False` and not configure\nthis backend in the underlying implementation.\n\nIf there is a cross-namespace reference to an *existing* object\nthat is not allowed by a ReferenceGrant, the controller must ensure the\n\"ResolvedRefs\"  condition on the Route is set to `status: False`,\nwith the \"RefNotPermitted\" reason and not configure this backend in the\nunderlying implementation.\n\nIn either error case, the Message of the `ResolvedRefs` Condition\nshould be used to provide more detail about the problem.\n\nSupport: Extended for Kubernetes Service\n\nSupport: Implementation-specific for any other resource";
          type = submoduleOf "gateway.networking.k8s.io.v1.GRPCRouteSpecRulesBackendRefsFiltersRequestMirrorBackendRef";
        };
        "fraction" = mkOption {
          description = "Fraction represents the fraction of requests that should be\nmirrored to BackendRef.\n\nOnly one of Fraction or Percent may be specified. If neither field\nis specified, 100% of requests will be mirrored.";
          type = types.nullOr (
            submoduleOf "gateway.networking.k8s.io.v1.GRPCRouteSpecRulesBackendRefsFiltersRequestMirrorFraction"
          );
        };
        "percent" = mkOption {
          description = "Percent represents the percentage of requests that should be\nmirrored to BackendRef. Its minimum value is 0 (indicating 0% of\nrequests) and its maximum value is 100 (indicating 100% of requests).\n\nOnly one of Fraction or Percent may be specified. If neither field\nis specified, 100% of requests will be mirrored.";
          type = types.nullOr types.int;
        };
      };

      config = {
        "fraction" = mkOverride 1002 null;
        "percent" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1.GRPCRouteSpecRulesBackendRefsFiltersRequestMirrorBackendRef" = {

      options = {
        "group" = mkOption {
          description = "Group is the group of the referent. For example, \"gateway.networking.k8s.io\".\nWhen unspecified or empty string, core API group is inferred.";
          type = types.nullOr types.str;
        };
        "kind" = mkOption {
          description = "Kind is the Kubernetes resource kind of the referent. For example\n\"Service\".\n\nDefaults to \"Service\" when not specified.\n\nExternalName services can refer to CNAME DNS records that may live\noutside of the cluster and as such are difficult to reason about in\nterms of conformance. They also may not be safe to forward to (see\nCVE-2021-25740 for more information). Implementations SHOULD NOT\nsupport ExternalName Services.\n\nSupport: Core (Services with a type other than ExternalName)\n\nSupport: Implementation-specific (Services with type ExternalName)";
          type = types.nullOr types.str;
        };
        "name" = mkOption {
          description = "Name is the name of the referent.";
          type = types.str;
        };
        "namespace" = mkOption {
          description = "Namespace is the namespace of the backend. When unspecified, the local\nnamespace is inferred.\n\nNote that when a namespace different than the local namespace is specified,\na ReferenceGrant object is required in the referent namespace to allow that\nnamespace's owner to accept the reference. See the ReferenceGrant\ndocumentation for details.\n\nSupport: Core";
          type = types.nullOr types.str;
        };
        "port" = mkOption {
          description = "Port specifies the destination port number to use for this resource.\nPort is required when the referent is a Kubernetes Service. In this\ncase, the port number is the service port number, not the target port.\nFor other resources, destination port might be derived from the referent\nresource or this field.";
          type = types.nullOr types.int;
        };
      };

      config = {
        "group" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
        "port" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1.GRPCRouteSpecRulesBackendRefsFiltersRequestMirrorFraction" = {

      options = {
        "denominator" = mkOption {
          description = "";
          type = types.nullOr types.int;
        };
        "numerator" = mkOption {
          description = "";
          type = types.int;
        };
      };

      config = {
        "denominator" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1.GRPCRouteSpecRulesBackendRefsFiltersResponseHeaderModifier" = {

      options = {
        "add" = mkOption {
          description = "Add adds the given header(s) (name, value) to the request\nbefore the action. It appends to any existing values associated\nwith the header name.\n\nInput:\n  GET /foo HTTP/1.1\n  my-header: foo\n\nConfig:\n  add:\n  - name: \"my-header\"\n    value: \"bar,baz\"\n\nOutput:\n  GET /foo HTTP/1.1\n  my-header: foo,bar,baz";
          type = types.nullOr (
            coerceAttrsOfSubmodulesToListByKey
              "gateway.networking.k8s.io.v1.GRPCRouteSpecRulesBackendRefsFiltersResponseHeaderModifierAdd"
              "name"
              [ "name" ]
          );
          apply = attrsToList;
        };
        "remove" = mkOption {
          description = "Remove the given header(s) from the HTTP request before the action. The\nvalue of Remove is a list of HTTP header names. Note that the header\nnames are case-insensitive (see\nhttps://datatracker.ietf.org/doc/html/rfc2616#section-4.2).\n\nInput:\n  GET /foo HTTP/1.1\n  my-header1: foo\n  my-header2: bar\n  my-header3: baz\n\nConfig:\n  remove: [\"my-header1\", \"my-header3\"]\n\nOutput:\n  GET /foo HTTP/1.1\n  my-header2: bar";
          type = types.nullOr (types.listOf types.str);
        };
        "set" = mkOption {
          description = "Set overwrites the request with the given header (name, value)\nbefore the action.\n\nInput:\n  GET /foo HTTP/1.1\n  my-header: foo\n\nConfig:\n  set:\n  - name: \"my-header\"\n    value: \"bar\"\n\nOutput:\n  GET /foo HTTP/1.1\n  my-header: bar";
          type = types.nullOr (
            coerceAttrsOfSubmodulesToListByKey
              "gateway.networking.k8s.io.v1.GRPCRouteSpecRulesBackendRefsFiltersResponseHeaderModifierSet"
              "name"
              [ "name" ]
          );
          apply = attrsToList;
        };
      };

      config = {
        "add" = mkOverride 1002 null;
        "remove" = mkOverride 1002 null;
        "set" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1.GRPCRouteSpecRulesBackendRefsFiltersResponseHeaderModifierAdd" = {

      options = {
        "name" = mkOption {
          description = "Name is the name of the HTTP Header to be matched. Name matching MUST be\ncase-insensitive. (See https://tools.ietf.org/html/rfc7230#section-3.2).\n\nIf multiple entries specify equivalent header names, the first entry with\nan equivalent name MUST be considered for a match. Subsequent entries\nwith an equivalent header name MUST be ignored. Due to the\ncase-insensitivity of header names, \"foo\" and \"Foo\" are considered\nequivalent.";
          type = types.str;
        };
        "value" = mkOption {
          description = "Value is the value of HTTP Header to be matched.";
          type = types.str;
        };
      };

      config = { };

    };
    "gateway.networking.k8s.io.v1.GRPCRouteSpecRulesBackendRefsFiltersResponseHeaderModifierSet" = {

      options = {
        "name" = mkOption {
          description = "Name is the name of the HTTP Header to be matched. Name matching MUST be\ncase-insensitive. (See https://tools.ietf.org/html/rfc7230#section-3.2).\n\nIf multiple entries specify equivalent header names, the first entry with\nan equivalent name MUST be considered for a match. Subsequent entries\nwith an equivalent header name MUST be ignored. Due to the\ncase-insensitivity of header names, \"foo\" and \"Foo\" are considered\nequivalent.";
          type = types.str;
        };
        "value" = mkOption {
          description = "Value is the value of HTTP Header to be matched.";
          type = types.str;
        };
      };

      config = { };

    };
    "gateway.networking.k8s.io.v1.GRPCRouteSpecRulesFilters" = {

      options = {
        "extensionRef" = mkOption {
          description = "ExtensionRef is an optional, implementation-specific extension to the\n\"filter\" behavior.  For example, resource \"myroutefilter\" in group\n\"networking.example.net\"). ExtensionRef MUST NOT be used for core and\nextended filters.\n\nSupport: Implementation-specific\n\nThis filter can be used multiple times within the same rule.";
          type = types.nullOr (
            submoduleOf "gateway.networking.k8s.io.v1.GRPCRouteSpecRulesFiltersExtensionRef"
          );
        };
        "requestHeaderModifier" = mkOption {
          description = "RequestHeaderModifier defines a schema for a filter that modifies request\nheaders.\n\nSupport: Core";
          type = types.nullOr (
            submoduleOf "gateway.networking.k8s.io.v1.GRPCRouteSpecRulesFiltersRequestHeaderModifier"
          );
        };
        "requestMirror" = mkOption {
          description = "RequestMirror defines a schema for a filter that mirrors requests.\nRequests are sent to the specified destination, but responses from\nthat destination are ignored.\n\nThis filter can be used multiple times within the same rule. Note that\nnot all implementations will be able to support mirroring to multiple\nbackends.\n\nSupport: Extended";
          type = types.nullOr (
            submoduleOf "gateway.networking.k8s.io.v1.GRPCRouteSpecRulesFiltersRequestMirror"
          );
        };
        "responseHeaderModifier" = mkOption {
          description = "ResponseHeaderModifier defines a schema for a filter that modifies response\nheaders.\n\nSupport: Extended";
          type = types.nullOr (
            submoduleOf "gateway.networking.k8s.io.v1.GRPCRouteSpecRulesFiltersResponseHeaderModifier"
          );
        };
        "type" = mkOption {
          description = "Type identifies the type of filter to apply. As with other API fields,\ntypes are classified into three conformance levels:\n\n- Core: Filter types and their corresponding configuration defined by\n  \"Support: Core\" in this package, e.g. \"RequestHeaderModifier\". All\n  implementations supporting GRPCRoute MUST support core filters.\n\n- Extended: Filter types and their corresponding configuration defined by\n  \"Support: Extended\" in this package, e.g. \"RequestMirror\". Implementers\n  are encouraged to support extended filters.\n\n- Implementation-specific: Filters that are defined and supported by specific vendors.\n  In the future, filters showing convergence in behavior across multiple\n  implementations will be considered for inclusion in extended or core\n  conformance levels. Filter-specific configuration for such filters\n  is specified using the ExtensionRef field. `Type` MUST be set to\n  \"ExtensionRef\" for custom filters.\n\nImplementers are encouraged to define custom implementation types to\nextend the core API with implementation-specific behavior.\n\nIf a reference to a custom filter type cannot be resolved, the filter\nMUST NOT be skipped. Instead, requests that would have been processed by\nthat filter MUST receive a HTTP error response.";
          type = types.str;
        };
      };

      config = {
        "extensionRef" = mkOverride 1002 null;
        "requestHeaderModifier" = mkOverride 1002 null;
        "requestMirror" = mkOverride 1002 null;
        "responseHeaderModifier" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1.GRPCRouteSpecRulesFiltersExtensionRef" = {

      options = {
        "group" = mkOption {
          description = "Group is the group of the referent. For example, \"gateway.networking.k8s.io\".\nWhen unspecified or empty string, core API group is inferred.";
          type = types.str;
        };
        "kind" = mkOption {
          description = "Kind is kind of the referent. For example \"HTTPRoute\" or \"Service\".";
          type = types.str;
        };
        "name" = mkOption {
          description = "Name is the name of the referent.";
          type = types.str;
        };
      };

      config = { };

    };
    "gateway.networking.k8s.io.v1.GRPCRouteSpecRulesFiltersRequestHeaderModifier" = {

      options = {
        "add" = mkOption {
          description = "Add adds the given header(s) (name, value) to the request\nbefore the action. It appends to any existing values associated\nwith the header name.\n\nInput:\n  GET /foo HTTP/1.1\n  my-header: foo\n\nConfig:\n  add:\n  - name: \"my-header\"\n    value: \"bar,baz\"\n\nOutput:\n  GET /foo HTTP/1.1\n  my-header: foo,bar,baz";
          type = types.nullOr (
            coerceAttrsOfSubmodulesToListByKey
              "gateway.networking.k8s.io.v1.GRPCRouteSpecRulesFiltersRequestHeaderModifierAdd"
              "name"
              [ "name" ]
          );
          apply = attrsToList;
        };
        "remove" = mkOption {
          description = "Remove the given header(s) from the HTTP request before the action. The\nvalue of Remove is a list of HTTP header names. Note that the header\nnames are case-insensitive (see\nhttps://datatracker.ietf.org/doc/html/rfc2616#section-4.2).\n\nInput:\n  GET /foo HTTP/1.1\n  my-header1: foo\n  my-header2: bar\n  my-header3: baz\n\nConfig:\n  remove: [\"my-header1\", \"my-header3\"]\n\nOutput:\n  GET /foo HTTP/1.1\n  my-header2: bar";
          type = types.nullOr (types.listOf types.str);
        };
        "set" = mkOption {
          description = "Set overwrites the request with the given header (name, value)\nbefore the action.\n\nInput:\n  GET /foo HTTP/1.1\n  my-header: foo\n\nConfig:\n  set:\n  - name: \"my-header\"\n    value: \"bar\"\n\nOutput:\n  GET /foo HTTP/1.1\n  my-header: bar";
          type = types.nullOr (
            coerceAttrsOfSubmodulesToListByKey
              "gateway.networking.k8s.io.v1.GRPCRouteSpecRulesFiltersRequestHeaderModifierSet"
              "name"
              [ "name" ]
          );
          apply = attrsToList;
        };
      };

      config = {
        "add" = mkOverride 1002 null;
        "remove" = mkOverride 1002 null;
        "set" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1.GRPCRouteSpecRulesFiltersRequestHeaderModifierAdd" = {

      options = {
        "name" = mkOption {
          description = "Name is the name of the HTTP Header to be matched. Name matching MUST be\ncase-insensitive. (See https://tools.ietf.org/html/rfc7230#section-3.2).\n\nIf multiple entries specify equivalent header names, the first entry with\nan equivalent name MUST be considered for a match. Subsequent entries\nwith an equivalent header name MUST be ignored. Due to the\ncase-insensitivity of header names, \"foo\" and \"Foo\" are considered\nequivalent.";
          type = types.str;
        };
        "value" = mkOption {
          description = "Value is the value of HTTP Header to be matched.";
          type = types.str;
        };
      };

      config = { };

    };
    "gateway.networking.k8s.io.v1.GRPCRouteSpecRulesFiltersRequestHeaderModifierSet" = {

      options = {
        "name" = mkOption {
          description = "Name is the name of the HTTP Header to be matched. Name matching MUST be\ncase-insensitive. (See https://tools.ietf.org/html/rfc7230#section-3.2).\n\nIf multiple entries specify equivalent header names, the first entry with\nan equivalent name MUST be considered for a match. Subsequent entries\nwith an equivalent header name MUST be ignored. Due to the\ncase-insensitivity of header names, \"foo\" and \"Foo\" are considered\nequivalent.";
          type = types.str;
        };
        "value" = mkOption {
          description = "Value is the value of HTTP Header to be matched.";
          type = types.str;
        };
      };

      config = { };

    };
    "gateway.networking.k8s.io.v1.GRPCRouteSpecRulesFiltersRequestMirror" = {

      options = {
        "backendRef" = mkOption {
          description = "BackendRef references a resource where mirrored requests are sent.\n\nMirrored requests must be sent only to a single destination endpoint\nwithin this BackendRef, irrespective of how many endpoints are present\nwithin this BackendRef.\n\nIf the referent cannot be found, this BackendRef is invalid and must be\ndropped from the Gateway. The controller must ensure the \"ResolvedRefs\"\ncondition on the Route status is set to `status: False` and not configure\nthis backend in the underlying implementation.\n\nIf there is a cross-namespace reference to an *existing* object\nthat is not allowed by a ReferenceGrant, the controller must ensure the\n\"ResolvedRefs\"  condition on the Route is set to `status: False`,\nwith the \"RefNotPermitted\" reason and not configure this backend in the\nunderlying implementation.\n\nIn either error case, the Message of the `ResolvedRefs` Condition\nshould be used to provide more detail about the problem.\n\nSupport: Extended for Kubernetes Service\n\nSupport: Implementation-specific for any other resource";
          type = submoduleOf "gateway.networking.k8s.io.v1.GRPCRouteSpecRulesFiltersRequestMirrorBackendRef";
        };
        "fraction" = mkOption {
          description = "Fraction represents the fraction of requests that should be\nmirrored to BackendRef.\n\nOnly one of Fraction or Percent may be specified. If neither field\nis specified, 100% of requests will be mirrored.";
          type = types.nullOr (
            submoduleOf "gateway.networking.k8s.io.v1.GRPCRouteSpecRulesFiltersRequestMirrorFraction"
          );
        };
        "percent" = mkOption {
          description = "Percent represents the percentage of requests that should be\nmirrored to BackendRef. Its minimum value is 0 (indicating 0% of\nrequests) and its maximum value is 100 (indicating 100% of requests).\n\nOnly one of Fraction or Percent may be specified. If neither field\nis specified, 100% of requests will be mirrored.";
          type = types.nullOr types.int;
        };
      };

      config = {
        "fraction" = mkOverride 1002 null;
        "percent" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1.GRPCRouteSpecRulesFiltersRequestMirrorBackendRef" = {

      options = {
        "group" = mkOption {
          description = "Group is the group of the referent. For example, \"gateway.networking.k8s.io\".\nWhen unspecified or empty string, core API group is inferred.";
          type = types.nullOr types.str;
        };
        "kind" = mkOption {
          description = "Kind is the Kubernetes resource kind of the referent. For example\n\"Service\".\n\nDefaults to \"Service\" when not specified.\n\nExternalName services can refer to CNAME DNS records that may live\noutside of the cluster and as such are difficult to reason about in\nterms of conformance. They also may not be safe to forward to (see\nCVE-2021-25740 for more information). Implementations SHOULD NOT\nsupport ExternalName Services.\n\nSupport: Core (Services with a type other than ExternalName)\n\nSupport: Implementation-specific (Services with type ExternalName)";
          type = types.nullOr types.str;
        };
        "name" = mkOption {
          description = "Name is the name of the referent.";
          type = types.str;
        };
        "namespace" = mkOption {
          description = "Namespace is the namespace of the backend. When unspecified, the local\nnamespace is inferred.\n\nNote that when a namespace different than the local namespace is specified,\na ReferenceGrant object is required in the referent namespace to allow that\nnamespace's owner to accept the reference. See the ReferenceGrant\ndocumentation for details.\n\nSupport: Core";
          type = types.nullOr types.str;
        };
        "port" = mkOption {
          description = "Port specifies the destination port number to use for this resource.\nPort is required when the referent is a Kubernetes Service. In this\ncase, the port number is the service port number, not the target port.\nFor other resources, destination port might be derived from the referent\nresource or this field.";
          type = types.nullOr types.int;
        };
      };

      config = {
        "group" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
        "port" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1.GRPCRouteSpecRulesFiltersRequestMirrorFraction" = {

      options = {
        "denominator" = mkOption {
          description = "";
          type = types.nullOr types.int;
        };
        "numerator" = mkOption {
          description = "";
          type = types.int;
        };
      };

      config = {
        "denominator" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1.GRPCRouteSpecRulesFiltersResponseHeaderModifier" = {

      options = {
        "add" = mkOption {
          description = "Add adds the given header(s) (name, value) to the request\nbefore the action. It appends to any existing values associated\nwith the header name.\n\nInput:\n  GET /foo HTTP/1.1\n  my-header: foo\n\nConfig:\n  add:\n  - name: \"my-header\"\n    value: \"bar,baz\"\n\nOutput:\n  GET /foo HTTP/1.1\n  my-header: foo,bar,baz";
          type = types.nullOr (
            coerceAttrsOfSubmodulesToListByKey
              "gateway.networking.k8s.io.v1.GRPCRouteSpecRulesFiltersResponseHeaderModifierAdd"
              "name"
              [ "name" ]
          );
          apply = attrsToList;
        };
        "remove" = mkOption {
          description = "Remove the given header(s) from the HTTP request before the action. The\nvalue of Remove is a list of HTTP header names. Note that the header\nnames are case-insensitive (see\nhttps://datatracker.ietf.org/doc/html/rfc2616#section-4.2).\n\nInput:\n  GET /foo HTTP/1.1\n  my-header1: foo\n  my-header2: bar\n  my-header3: baz\n\nConfig:\n  remove: [\"my-header1\", \"my-header3\"]\n\nOutput:\n  GET /foo HTTP/1.1\n  my-header2: bar";
          type = types.nullOr (types.listOf types.str);
        };
        "set" = mkOption {
          description = "Set overwrites the request with the given header (name, value)\nbefore the action.\n\nInput:\n  GET /foo HTTP/1.1\n  my-header: foo\n\nConfig:\n  set:\n  - name: \"my-header\"\n    value: \"bar\"\n\nOutput:\n  GET /foo HTTP/1.1\n  my-header: bar";
          type = types.nullOr (
            coerceAttrsOfSubmodulesToListByKey
              "gateway.networking.k8s.io.v1.GRPCRouteSpecRulesFiltersResponseHeaderModifierSet"
              "name"
              [ "name" ]
          );
          apply = attrsToList;
        };
      };

      config = {
        "add" = mkOverride 1002 null;
        "remove" = mkOverride 1002 null;
        "set" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1.GRPCRouteSpecRulesFiltersResponseHeaderModifierAdd" = {

      options = {
        "name" = mkOption {
          description = "Name is the name of the HTTP Header to be matched. Name matching MUST be\ncase-insensitive. (See https://tools.ietf.org/html/rfc7230#section-3.2).\n\nIf multiple entries specify equivalent header names, the first entry with\nan equivalent name MUST be considered for a match. Subsequent entries\nwith an equivalent header name MUST be ignored. Due to the\ncase-insensitivity of header names, \"foo\" and \"Foo\" are considered\nequivalent.";
          type = types.str;
        };
        "value" = mkOption {
          description = "Value is the value of HTTP Header to be matched.";
          type = types.str;
        };
      };

      config = { };

    };
    "gateway.networking.k8s.io.v1.GRPCRouteSpecRulesFiltersResponseHeaderModifierSet" = {

      options = {
        "name" = mkOption {
          description = "Name is the name of the HTTP Header to be matched. Name matching MUST be\ncase-insensitive. (See https://tools.ietf.org/html/rfc7230#section-3.2).\n\nIf multiple entries specify equivalent header names, the first entry with\nan equivalent name MUST be considered for a match. Subsequent entries\nwith an equivalent header name MUST be ignored. Due to the\ncase-insensitivity of header names, \"foo\" and \"Foo\" are considered\nequivalent.";
          type = types.str;
        };
        "value" = mkOption {
          description = "Value is the value of HTTP Header to be matched.";
          type = types.str;
        };
      };

      config = { };

    };
    "gateway.networking.k8s.io.v1.GRPCRouteSpecRulesMatches" = {

      options = {
        "headers" = mkOption {
          description = "Headers specifies gRPC request header matchers. Multiple match values are\nANDed together, meaning, a request MUST match all the specified headers\nto select the route.";
          type = types.nullOr (
            coerceAttrsOfSubmodulesToListByKey "gateway.networking.k8s.io.v1.GRPCRouteSpecRulesMatchesHeaders"
              "name"
              [ "name" ]
          );
          apply = attrsToList;
        };
        "method" = mkOption {
          description = "Method specifies a gRPC request service/method matcher. If this field is\nnot specified, all services and methods will match.";
          type = types.nullOr (submoduleOf "gateway.networking.k8s.io.v1.GRPCRouteSpecRulesMatchesMethod");
        };
      };

      config = {
        "headers" = mkOverride 1002 null;
        "method" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1.GRPCRouteSpecRulesMatchesHeaders" = {

      options = {
        "name" = mkOption {
          description = "Name is the name of the gRPC Header to be matched.\n\nIf multiple entries specify equivalent header names, only the first\nentry with an equivalent name MUST be considered for a match. Subsequent\nentries with an equivalent header name MUST be ignored. Due to the\ncase-insensitivity of header names, \"foo\" and \"Foo\" are considered\nequivalent.";
          type = types.str;
        };
        "type" = mkOption {
          description = "Type specifies how to match against the value of the header.";
          type = types.nullOr types.str;
        };
        "value" = mkOption {
          description = "Value is the value of the gRPC Header to be matched.";
          type = types.str;
        };
      };

      config = {
        "type" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1.GRPCRouteSpecRulesMatchesMethod" = {

      options = {
        "method" = mkOption {
          description = "Value of the method to match against. If left empty or omitted, will\nmatch all services.\n\nAt least one of Service and Method MUST be a non-empty string.";
          type = types.nullOr types.str;
        };
        "service" = mkOption {
          description = "Value of the service to match against. If left empty or omitted, will\nmatch any service.\n\nAt least one of Service and Method MUST be a non-empty string.";
          type = types.nullOr types.str;
        };
        "type" = mkOption {
          description = "Type specifies how to match against the service and/or method.\nSupport: Core (Exact with service and method specified)\n\nSupport: Implementation-specific (Exact with method specified but no service specified)\n\nSupport: Implementation-specific (RegularExpression)";
          type = types.nullOr types.str;
        };
      };

      config = {
        "method" = mkOverride 1002 null;
        "service" = mkOverride 1002 null;
        "type" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1.GRPCRouteStatus" = {

      options = {
        "parents" = mkOption {
          description = "Parents is a list of parent resources (usually Gateways) that are\nassociated with the route, and the status of the route with respect to\neach parent. When this route attaches to a parent, the controller that\nmanages the parent must add an entry to this list when the controller\nfirst sees the route and should update the entry as appropriate when the\nroute or gateway is modified.\n\nNote that parent references that cannot be resolved by an implementation\nof this API will not be added to this list. Implementations of this API\ncan only populate Route status for the Gateways/parent resources they are\nresponsible for.\n\nA maximum of 32 Gateways will be represented in this list. An empty list\nmeans the route has not been attached to any Gateway.";
          type = types.listOf (submoduleOf "gateway.networking.k8s.io.v1.GRPCRouteStatusParents");
        };
      };

      config = { };

    };
    "gateway.networking.k8s.io.v1.GRPCRouteStatusParents" = {

      options = {
        "conditions" = mkOption {
          description = "Conditions describes the status of the route with respect to the Gateway.\nNote that the route's availability is also subject to the Gateway's own\nstatus conditions and listener status.\n\nIf the Route's ParentRef specifies an existing Gateway that supports\nRoutes of this kind AND that Gateway's controller has sufficient access,\nthen that Gateway's controller MUST set the \"Accepted\" condition on the\nRoute, to indicate whether the route has been accepted or rejected by the\nGateway, and why.\n\nA Route MUST be considered \"Accepted\" if at least one of the Route's\nrules is implemented by the Gateway.\n\nThere are a number of cases where the \"Accepted\" condition may not be set\ndue to lack of controller visibility, that includes when:\n\n* The Route refers to a nonexistent parent.\n* The Route is of a type that the controller does not support.\n* The Route is in a namespace the controller does not have access to.";
          type = types.listOf (submoduleOf "gateway.networking.k8s.io.v1.GRPCRouteStatusParentsConditions");
        };
        "controllerName" = mkOption {
          description = "ControllerName is a domain/path string that indicates the name of the\ncontroller that wrote this status. This corresponds with the\ncontrollerName field on GatewayClass.\n\nExample: \"example.net/gateway-controller\".\n\nThe format of this field is DOMAIN \"/\" PATH, where DOMAIN and PATH are\nvalid Kubernetes names\n(https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names).\n\nControllers MUST populate this field when writing status. Controllers should ensure that\nentries to status populated with their ControllerName are cleaned up when they are no\nlonger necessary.";
          type = types.str;
        };
        "parentRef" = mkOption {
          description = "ParentRef corresponds with a ParentRef in the spec that this\nRouteParentStatus struct describes the status of.";
          type = submoduleOf "gateway.networking.k8s.io.v1.GRPCRouteStatusParentsParentRef";
        };
      };

      config = { };

    };
    "gateway.networking.k8s.io.v1.GRPCRouteStatusParentsConditions" = {

      options = {
        "lastTransitionTime" = mkOption {
          description = "lastTransitionTime is the last time the condition transitioned from one status to another.\nThis should be when the underlying condition changed.  If that is not known, then using the time when the API field changed is acceptable.";
          type = types.str;
        };
        "message" = mkOption {
          description = "message is a human readable message indicating details about the transition.\nThis may be an empty string.";
          type = types.str;
        };
        "observedGeneration" = mkOption {
          description = "observedGeneration represents the .metadata.generation that the condition was set based upon.\nFor instance, if .metadata.generation is currently 12, but the .status.conditions[x].observedGeneration is 9, the condition is out of date\nwith respect to the current state of the instance.";
          type = types.nullOr types.int;
        };
        "reason" = mkOption {
          description = "reason contains a programmatic identifier indicating the reason for the condition's last transition.\nProducers of specific condition types may define expected values and meanings for this field,\nand whether the values are considered a guaranteed API.\nThe value should be a CamelCase string.\nThis field may not be empty.";
          type = types.str;
        };
        "status" = mkOption {
          description = "status of the condition, one of True, False, Unknown.";
          type = types.str;
        };
        "type" = mkOption {
          description = "type of condition in CamelCase or in foo.example.com/CamelCase.";
          type = types.str;
        };
      };

      config = {
        "observedGeneration" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1.GRPCRouteStatusParentsParentRef" = {

      options = {
        "group" = mkOption {
          description = "Group is the group of the referent.\nWhen unspecified, \"gateway.networking.k8s.io\" is inferred.\nTo set the core API group (such as for a \"Service\" kind referent),\nGroup must be explicitly set to \"\" (empty string).\n\nSupport: Core";
          type = types.nullOr types.str;
        };
        "kind" = mkOption {
          description = "Kind is kind of the referent.\n\nThere are two kinds of parent resources with \"Core\" support:\n\n* Gateway (Gateway conformance profile)\n* Service (Mesh conformance profile, ClusterIP Services only)\n\nSupport for other resources is Implementation-Specific.";
          type = types.nullOr types.str;
        };
        "name" = mkOption {
          description = "Name is the name of the referent.\n\nSupport: Core";
          type = types.str;
        };
        "namespace" = mkOption {
          description = "Namespace is the namespace of the referent. When unspecified, this refers\nto the local namespace of the Route.\n\nNote that there are specific rules for ParentRefs which cross namespace\nboundaries. Cross-namespace references are only valid if they are explicitly\nallowed by something in the namespace they are referring to. For example:\nGateway has the AllowedRoutes field, and ReferenceGrant provides a\ngeneric way to enable any other kind of cross-namespace reference.\n\nSupport: Core";
          type = types.nullOr types.str;
        };
        "port" = mkOption {
          description = "Port is the network port this Route targets. It can be interpreted\ndifferently based on the type of parent resource.\n\nWhen the parent resource is a Gateway, this targets all listeners\nlistening on the specified port that also support this kind of Route(and\nselect this Route). It's not recommended to set `Port` unless the\nnetworking behaviors specified in a Route must apply to a specific port\nas opposed to a listener(s) whose port(s) may be changed. When both Port\nand SectionName are specified, the name and port of the selected listener\nmust match both specified values.\n\nImplementations MAY choose to support other parent resources.\nImplementations supporting other types of parent resources MUST clearly\ndocument how/if Port is interpreted.\n\nFor the purpose of status, an attachment is considered successful as\nlong as the parent resource accepts it partially. For example, Gateway\nlisteners can restrict which Routes can attach to them by Route kind,\nnamespace, or hostname. If 1 of 2 Gateway listeners accept attachment\nfrom the referencing Route, the Route MUST be considered successfully\nattached. If no Gateway listeners accept attachment from this Route,\nthe Route MUST be considered detached from the Gateway.\n\nSupport: Extended";
          type = types.nullOr types.int;
        };
        "sectionName" = mkOption {
          description = "SectionName is the name of a section within the target resource. In the\nfollowing resources, SectionName is interpreted as the following:\n\n* Gateway: Listener name. When both Port (experimental) and SectionName\nare specified, the name and port of the selected listener must match\nboth specified values.\n* Service: Port name. When both Port (experimental) and SectionName\nare specified, the name and port of the selected listener must match\nboth specified values.\n\nImplementations MAY choose to support attaching Routes to other resources.\nIf that is the case, they MUST clearly document how SectionName is\ninterpreted.\n\nWhen unspecified (empty string), this will reference the entire resource.\nFor the purpose of status, an attachment is considered successful if at\nleast one section in the parent resource accepts it. For example, Gateway\nlisteners can restrict which Routes can attach to them by Route kind,\nnamespace, or hostname. If 1 of 2 Gateway listeners accept attachment from\nthe referencing Route, the Route MUST be considered successfully\nattached. If no Gateway listeners accept attachment from this Route, the\nRoute MUST be considered detached from the Gateway.\n\nSupport: Core";
          type = types.nullOr types.str;
        };
      };

      config = {
        "group" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
        "port" = mkOverride 1002 null;
        "sectionName" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1.Gateway" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object.\nServers should convert recognized schemas to the latest internal value, and\nmay reject unrecognized values.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = types.nullOr types.str;
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents.\nServers may infer this from the endpoint the client submits requests to.\nCannot be updated.\nIn CamelCase.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = types.nullOr types.str;
        };
        "metadata" = mkOption {
          description = "Standard object's metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = types.nullOr (globalSubmoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta");
        };
        "spec" = mkOption {
          description = "Spec defines the desired state of Gateway.";
          type = submoduleOf "gateway.networking.k8s.io.v1.GatewaySpec";
        };
        "status" = mkOption {
          description = "Status defines the current state of Gateway.";
          type = types.nullOr (submoduleOf "gateway.networking.k8s.io.v1.GatewayStatus");
        };
      };

      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1.GatewayClass" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object.\nServers should convert recognized schemas to the latest internal value, and\nmay reject unrecognized values.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = types.nullOr types.str;
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents.\nServers may infer this from the endpoint the client submits requests to.\nCannot be updated.\nIn CamelCase.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = types.nullOr types.str;
        };
        "metadata" = mkOption {
          description = "Standard object's metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = types.nullOr (globalSubmoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta");
        };
        "spec" = mkOption {
          description = "Spec defines the desired state of GatewayClass.";
          type = submoduleOf "gateway.networking.k8s.io.v1.GatewayClassSpec";
        };
        "status" = mkOption {
          description = "Status defines the current state of GatewayClass.\n\nImplementations MUST populate status on all GatewayClass resources which\nspecify their controller name.";
          type = types.nullOr (submoduleOf "gateway.networking.k8s.io.v1.GatewayClassStatus");
        };
      };

      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1.GatewayClassSpec" = {

      options = {
        "controllerName" = mkOption {
          description = "ControllerName is the name of the controller that is managing Gateways of\nthis class. The value of this field MUST be a domain prefixed path.\n\nExample: \"example.net/gateway-controller\".\n\nThis field is not mutable and cannot be empty.\n\nSupport: Core";
          type = types.str;
        };
        "description" = mkOption {
          description = "Description helps describe a GatewayClass with more details.";
          type = types.nullOr types.str;
        };
        "parametersRef" = mkOption {
          description = "ParametersRef is a reference to a resource that contains the configuration\nparameters corresponding to the GatewayClass. This is optional if the\ncontroller does not require any additional configuration.\n\nParametersRef can reference a standard Kubernetes resource, i.e. ConfigMap,\nor an implementation-specific custom resource. The resource can be\ncluster-scoped or namespace-scoped.\n\nIf the referent cannot be found, refers to an unsupported kind, or when\nthe data within that resource is malformed, the GatewayClass SHOULD be\nrejected with the \"Accepted\" status condition set to \"False\" and an\n\"InvalidParameters\" reason.\n\nA Gateway for this GatewayClass may provide its own `parametersRef`. When both are specified,\nthe merging behavior is implementation specific.\nIt is generally recommended that GatewayClass provides defaults that can be overridden by a Gateway.\n\nSupport: Implementation-specific";
          type = types.nullOr (submoduleOf "gateway.networking.k8s.io.v1.GatewayClassSpecParametersRef");
        };
      };

      config = {
        "description" = mkOverride 1002 null;
        "parametersRef" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1.GatewayClassSpecParametersRef" = {

      options = {
        "group" = mkOption {
          description = "Group is the group of the referent.";
          type = types.str;
        };
        "kind" = mkOption {
          description = "Kind is kind of the referent.";
          type = types.str;
        };
        "name" = mkOption {
          description = "Name is the name of the referent.";
          type = types.str;
        };
        "namespace" = mkOption {
          description = "Namespace is the namespace of the referent.\nThis field is required when referring to a Namespace-scoped resource and\nMUST be unset when referring to a Cluster-scoped resource.";
          type = types.nullOr types.str;
        };
      };

      config = {
        "namespace" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1.GatewayClassStatus" = {

      options = {
        "conditions" = mkOption {
          description = "Conditions is the current status from the controller for\nthis GatewayClass.\n\nControllers should prefer to publish conditions using values\nof GatewayClassConditionType for the type of each Condition.";
          type = types.nullOr (
            types.listOf (submoduleOf "gateway.networking.k8s.io.v1.GatewayClassStatusConditions")
          );
        };
        "supportedFeatures" = mkOption {
          description = "SupportedFeatures is the set of features the GatewayClass support.\nIt MUST be sorted in ascending alphabetical order by the Name key.";
          type = types.nullOr (
            coerceAttrsOfSubmodulesToListByKey
              "gateway.networking.k8s.io.v1.GatewayClassStatusSupportedFeatures"
              "name"
              [ "name" ]
          );
          apply = attrsToList;
        };
      };

      config = {
        "conditions" = mkOverride 1002 null;
        "supportedFeatures" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1.GatewayClassStatusConditions" = {

      options = {
        "lastTransitionTime" = mkOption {
          description = "lastTransitionTime is the last time the condition transitioned from one status to another.\nThis should be when the underlying condition changed.  If that is not known, then using the time when the API field changed is acceptable.";
          type = types.str;
        };
        "message" = mkOption {
          description = "message is a human readable message indicating details about the transition.\nThis may be an empty string.";
          type = types.str;
        };
        "observedGeneration" = mkOption {
          description = "observedGeneration represents the .metadata.generation that the condition was set based upon.\nFor instance, if .metadata.generation is currently 12, but the .status.conditions[x].observedGeneration is 9, the condition is out of date\nwith respect to the current state of the instance.";
          type = types.nullOr types.int;
        };
        "reason" = mkOption {
          description = "reason contains a programmatic identifier indicating the reason for the condition's last transition.\nProducers of specific condition types may define expected values and meanings for this field,\nand whether the values are considered a guaranteed API.\nThe value should be a CamelCase string.\nThis field may not be empty.";
          type = types.str;
        };
        "status" = mkOption {
          description = "status of the condition, one of True, False, Unknown.";
          type = types.str;
        };
        "type" = mkOption {
          description = "type of condition in CamelCase or in foo.example.com/CamelCase.";
          type = types.str;
        };
      };

      config = {
        "observedGeneration" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1.GatewayClassStatusSupportedFeatures" = {

      options = {
        "name" = mkOption {
          description = "FeatureName is used to describe distinct features that are covered by\nconformance tests.";
          type = types.str;
        };
      };

      config = { };

    };
    "gateway.networking.k8s.io.v1.GatewaySpec" = {

      options = {
        "addresses" = mkOption {
          description = "Addresses requested for this Gateway. This is optional and behavior can\ndepend on the implementation. If a value is set in the spec and the\nrequested address is invalid or unavailable, the implementation MUST\nindicate this in an associated entry in GatewayStatus.Conditions.\n\nThe Addresses field represents a request for the address(es) on the\n\"outside of the Gateway\", that traffic bound for this Gateway will use.\nThis could be the IP address or hostname of an external load balancer or\nother networking infrastructure, or some other address that traffic will\nbe sent to.\n\nIf no Addresses are specified, the implementation MAY schedule the\nGateway in an implementation-specific manner, assigning an appropriate\nset of Addresses.\n\nThe implementation MUST bind all Listeners to every GatewayAddress that\nit assigns to the Gateway and add a corresponding entry in\nGatewayStatus.Addresses.\n\nSupport: Extended";
          type = types.nullOr (
            types.listOf (submoduleOf "gateway.networking.k8s.io.v1.GatewaySpecAddresses")
          );
        };
        "gatewayClassName" = mkOption {
          description = "GatewayClassName used for this Gateway. This is the name of a\nGatewayClass resource.";
          type = types.str;
        };
        "infrastructure" = mkOption {
          description = "Infrastructure defines infrastructure level attributes about this Gateway instance.\n\nSupport: Extended";
          type = types.nullOr (submoduleOf "gateway.networking.k8s.io.v1.GatewaySpecInfrastructure");
        };
        "listeners" = mkOption {
          description = "Listeners associated with this Gateway. Listeners define\nlogical endpoints that are bound on this Gateway's addresses.\nAt least one Listener MUST be specified.\n\n## Distinct Listeners\n\nEach Listener in a set of Listeners (for example, in a single Gateway)\nMUST be _distinct_, in that a traffic flow MUST be able to be assigned to\nexactly one listener. (This section uses \"set of Listeners\" rather than\n\"Listeners in a single Gateway\" because implementations MAY merge configuration\nfrom multiple Gateways onto a single data plane, and these rules _also_\napply in that case).\n\nPractically, this means that each listener in a set MUST have a unique\ncombination of Port, Protocol, and, if supported by the protocol, Hostname.\n\nSome combinations of port, protocol, and TLS settings are considered\nCore support and MUST be supported by implementations based on the objects\nthey support:\n\nHTTPRoute\n\n1. HTTPRoute, Port: 80, Protocol: HTTP\n2. HTTPRoute, Port: 443, Protocol: HTTPS, TLS Mode: Terminate, TLS keypair provided\n\nTLSRoute\n\n1. TLSRoute, Port: 443, Protocol: TLS, TLS Mode: Passthrough\n\n\"Distinct\" Listeners have the following property:\n\n**The implementation can match inbound requests to a single distinct\nListener**.\n\nWhen multiple Listeners share values for fields (for\nexample, two Listeners with the same Port value), the implementation\ncan match requests to only one of the Listeners using other\nListener fields.\n\nWhen multiple listeners have the same value for the Protocol field, then\neach of the Listeners with matching Protocol values MUST have different\nvalues for other fields.\n\nThe set of fields that MUST be different for a Listener differs per protocol.\nThe following rules define the rules for what fields MUST be considered for\nListeners to be distinct with each protocol currently defined in the\nGateway API spec.\n\nThe set of listeners that all share a protocol value MUST have _different_\nvalues for _at least one_ of these fields to be distinct:\n\n* **HTTP, HTTPS, TLS**: Port, Hostname\n* **TCP, UDP**: Port\n\nOne **very** important rule to call out involves what happens when an\nimplementation:\n\n* Supports TCP protocol Listeners, as well as HTTP, HTTPS, or TLS protocol\n  Listeners, and\n* sees HTTP, HTTPS, or TLS protocols with the same `port` as one with TCP\n  Protocol.\n\nIn this case all the Listeners that share a port with the\nTCP Listener are not distinct and so MUST NOT be accepted.\n\nIf an implementation does not support TCP Protocol Listeners, then the\nprevious rule does not apply, and the TCP Listeners SHOULD NOT be\naccepted.\n\nNote that the `tls` field is not used for determining if a listener is distinct, because\nListeners that _only_ differ on TLS config will still conflict in all cases.\n\n### Listeners that are distinct only by Hostname\n\nWhen the Listeners are distinct based only on Hostname, inbound request\nhostnames MUST match from the most specific to least specific Hostname\nvalues to choose the correct Listener and its associated set of Routes.\n\nExact matches MUST be processed before wildcard matches, and wildcard\nmatches MUST be processed before fallback (empty Hostname value)\nmatches. For example, `\"foo.example.com\"` takes precedence over\n`\"*.example.com\"`, and `\"*.example.com\"` takes precedence over `\"\"`.\n\nAdditionally, if there are multiple wildcard entries, more specific\nwildcard entries must be processed before less specific wildcard entries.\nFor example, `\"*.foo.example.com\"` takes precedence over `\"*.example.com\"`.\n\nThe precise definition here is that the higher the number of dots in the\nhostname to the right of the wildcard character, the higher the precedence.\n\nThe wildcard character will match any number of characters _and dots_ to\nthe left, however, so `\"*.example.com\"` will match both\n`\"foo.bar.example.com\"` _and_ `\"bar.example.com\"`.\n\n## Handling indistinct Listeners\n\nIf a set of Listeners contains Listeners that are not distinct, then those\nListeners are _Conflicted_, and the implementation MUST set the \"Conflicted\"\ncondition in the Listener Status to \"True\".\n\nThe words \"indistinct\" and \"conflicted\" are considered equivalent for the\npurpose of this documentation.\n\nImplementations MAY choose to accept a Gateway with some Conflicted\nListeners only if they only accept the partial Listener set that contains\nno Conflicted Listeners.\n\nSpecifically, an implementation MAY accept a partial Listener set subject to\nthe following rules:\n\n* The implementation MUST NOT pick one conflicting Listener as the winner.\n  ALL indistinct Listeners must not be accepted for processing.\n* At least one distinct Listener MUST be present, or else the Gateway effectively\n  contains _no_ Listeners, and must be rejected from processing as a whole.\n\nThe implementation MUST set a \"ListenersNotValid\" condition on the\nGateway Status when the Gateway contains Conflicted Listeners whether or\nnot they accept the Gateway. That Condition SHOULD clearly\nindicate in the Message which Listeners are conflicted, and which are\nAccepted. Additionally, the Listener status for those listeners SHOULD\nindicate which Listeners are conflicted and not Accepted.\n\n## General Listener behavior\n\nNote that, for all distinct Listeners, requests SHOULD match at most one Listener.\nFor example, if Listeners are defined for \"foo.example.com\" and \"*.example.com\", a\nrequest to \"foo.example.com\" SHOULD only be routed using routes attached\nto the \"foo.example.com\" Listener (and not the \"*.example.com\" Listener).\n\nThis concept is known as \"Listener Isolation\", and it is an Extended feature\nof Gateway API. Implementations that do not support Listener Isolation MUST\nclearly document this, and MUST NOT claim support for the\n`GatewayHTTPListenerIsolation` feature.\n\nImplementations that _do_ support Listener Isolation SHOULD claim support\nfor the Extended `GatewayHTTPListenerIsolation` feature and pass the associated\nconformance tests.\n\n## Compatible Listeners\n\nA Gateway's Listeners are considered _compatible_ if:\n\n1. They are distinct.\n2. The implementation can serve them in compliance with the Addresses\n   requirement that all Listeners are available on all assigned\n   addresses.\n\nCompatible combinations in Extended support are expected to vary across\nimplementations. A combination that is compatible for one implementation\nmay not be compatible for another.\n\nFor example, an implementation that cannot serve both TCP and UDP listeners\non the same address, or cannot mix HTTPS and generic TLS listens on the same port\nwould not consider those cases compatible, even though they are distinct.\n\nImplementations MAY merge separate Gateways onto a single set of\nAddresses if all Listeners across all Gateways are compatible.\n\nIn a future release the MinItems=1 requirement MAY be dropped.\n\nSupport: Core";
          type =
            coerceAttrsOfSubmodulesToListByKey "gateway.networking.k8s.io.v1.GatewaySpecListeners" "name"
              [
                "name"
              ];
          apply = attrsToList;
        };
      };

      config = {
        "addresses" = mkOverride 1002 null;
        "infrastructure" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1.GatewaySpecAddresses" = {

      options = {
        "type" = mkOption {
          description = "Type of the address.";
          type = types.nullOr types.str;
        };
        "value" = mkOption {
          description = "When a value is unspecified, an implementation SHOULD automatically\nassign an address matching the requested type if possible.\n\nIf an implementation does not support an empty value, they MUST set the\n\"Programmed\" condition in status to False with a reason of \"AddressNotAssigned\".\n\nExamples: `1.2.3.4`, `128::1`, `my-ip-address`.";
          type = types.nullOr types.str;
        };
      };

      config = {
        "type" = mkOverride 1002 null;
        "value" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1.GatewaySpecInfrastructure" = {

      options = {
        "annotations" = mkOption {
          description = "Annotations that SHOULD be applied to any resources created in response to this Gateway.\n\nFor implementations creating other Kubernetes objects, this should be the `metadata.annotations` field on resources.\nFor other implementations, this refers to any relevant (implementation specific) \"annotations\" concepts.\n\nAn implementation may chose to add additional implementation-specific annotations as they see fit.\n\nSupport: Extended";
          type = types.nullOr (types.attrsOf types.str);
        };
        "labels" = mkOption {
          description = "Labels that SHOULD be applied to any resources created in response to this Gateway.\n\nFor implementations creating other Kubernetes objects, this should be the `metadata.labels` field on resources.\nFor other implementations, this refers to any relevant (implementation specific) \"labels\" concepts.\n\nAn implementation may chose to add additional implementation-specific labels as they see fit.\n\nIf an implementation maps these labels to Pods, or any other resource that would need to be recreated when labels\nchange, it SHOULD clearly warn about this behavior in documentation.\n\nSupport: Extended";
          type = types.nullOr (types.attrsOf types.str);
        };
        "parametersRef" = mkOption {
          description = "ParametersRef is a reference to a resource that contains the configuration\nparameters corresponding to the Gateway. This is optional if the\ncontroller does not require any additional configuration.\n\nThis follows the same semantics as GatewayClass's `parametersRef`, but on a per-Gateway basis\n\nThe Gateway's GatewayClass may provide its own `parametersRef`. When both are specified,\nthe merging behavior is implementation specific.\nIt is generally recommended that GatewayClass provides defaults that can be overridden by a Gateway.\n\nIf the referent cannot be found, refers to an unsupported kind, or when\nthe data within that resource is malformed, the Gateway SHOULD be\nrejected with the \"Accepted\" status condition set to \"False\" and an\n\"InvalidParameters\" reason.\n\nSupport: Implementation-specific";
          type = types.nullOr (
            submoduleOf "gateway.networking.k8s.io.v1.GatewaySpecInfrastructureParametersRef"
          );
        };
      };

      config = {
        "annotations" = mkOverride 1002 null;
        "labels" = mkOverride 1002 null;
        "parametersRef" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1.GatewaySpecInfrastructureParametersRef" = {

      options = {
        "group" = mkOption {
          description = "Group is the group of the referent.";
          type = types.str;
        };
        "kind" = mkOption {
          description = "Kind is kind of the referent.";
          type = types.str;
        };
        "name" = mkOption {
          description = "Name is the name of the referent.";
          type = types.str;
        };
      };

      config = { };

    };
    "gateway.networking.k8s.io.v1.GatewaySpecListeners" = {

      options = {
        "allowedRoutes" = mkOption {
          description = "AllowedRoutes defines the types of routes that MAY be attached to a\nListener and the trusted namespaces where those Route resources MAY be\npresent.\n\nAlthough a client request may match multiple route rules, only one rule\nmay ultimately receive the request. Matching precedence MUST be\ndetermined in order of the following criteria:\n\n* The most specific match as defined by the Route type.\n* The oldest Route based on creation timestamp. For example, a Route with\n  a creation timestamp of \"2020-09-08 01:02:03\" is given precedence over\n  a Route with a creation timestamp of \"2020-09-08 01:02:04\".\n* If everything else is equivalent, the Route appearing first in\n  alphabetical order (namespace/name) should be given precedence. For\n  example, foo/bar is given precedence over foo/baz.\n\nAll valid rules within a Route attached to this Listener should be\nimplemented. Invalid Route rules can be ignored (sometimes that will mean\nthe full Route). If a Route rule transitions from valid to invalid,\nsupport for that Route rule should be dropped to ensure consistency. For\nexample, even if a filter specified by a Route rule is invalid, the rest\nof the rules within that Route should still be supported.\n\nSupport: Core";
          type = types.nullOr (submoduleOf "gateway.networking.k8s.io.v1.GatewaySpecListenersAllowedRoutes");
        };
        "hostname" = mkOption {
          description = "Hostname specifies the virtual hostname to match for protocol types that\ndefine this concept. When unspecified, all hostnames are matched. This\nfield is ignored for protocols that don't require hostname based\nmatching.\n\nImplementations MUST apply Hostname matching appropriately for each of\nthe following protocols:\n\n* TLS: The Listener Hostname MUST match the SNI.\n* HTTP: The Listener Hostname MUST match the Host header of the request.\n* HTTPS: The Listener Hostname SHOULD match both the SNI and Host header.\n  Note that this does not require the SNI and Host header to be the same.\n  The semantics of this are described in more detail below.\n\nTo ensure security, Section 11.1 of RFC-6066 emphasizes that server\nimplementations that rely on SNI hostname matching MUST also verify\nhostnames within the application protocol.\n\nSection 9.1.2 of RFC-7540 provides a mechanism for servers to reject the\nreuse of a connection by responding with the HTTP 421 Misdirected Request\nstatus code. This indicates that the origin server has rejected the\nrequest because it appears to have been misdirected.\n\nTo detect misdirected requests, Gateways SHOULD match the authority of\nthe requests with all the SNI hostname(s) configured across all the\nGateway Listeners on the same port and protocol:\n\n* If another Listener has an exact match or more specific wildcard entry,\n  the Gateway SHOULD return a 421.\n* If the current Listener (selected by SNI matching during ClientHello)\n  does not match the Host:\n    * If another Listener does match the Host the Gateway SHOULD return a\n      421.\n    * If no other Listener matches the Host, the Gateway MUST return a\n      404.\n\nFor HTTPRoute and TLSRoute resources, there is an interaction with the\n`spec.hostnames` array. When both listener and route specify hostnames,\nthere MUST be an intersection between the values for a Route to be\naccepted. For more information, refer to the Route specific Hostnames\ndocumentation.\n\nHostnames that are prefixed with a wildcard label (`*.`) are interpreted\nas a suffix match. That means that a match for `*.example.com` would match\nboth `test.example.com`, and `foo.test.example.com`, but not `example.com`.\n\nSupport: Core";
          type = types.nullOr types.str;
        };
        "name" = mkOption {
          description = "Name is the name of the Listener. This name MUST be unique within a\nGateway.\n\nSupport: Core";
          type = types.str;
        };
        "port" = mkOption {
          description = "Port is the network port. Multiple listeners may use the\nsame port, subject to the Listener compatibility rules.\n\nSupport: Core";
          type = types.int;
        };
        "protocol" = mkOption {
          description = "Protocol specifies the network protocol this listener expects to receive.\n\nSupport: Core";
          type = types.str;
        };
        "tls" = mkOption {
          description = "TLS is the TLS configuration for the Listener. This field is required if\nthe Protocol field is \"HTTPS\" or \"TLS\". It is invalid to set this field\nif the Protocol field is \"HTTP\", \"TCP\", or \"UDP\".\n\nThe association of SNIs to Certificate defined in ListenerTLSConfig is\ndefined based on the Hostname field for this listener.\n\nThe GatewayClass MUST use the longest matching SNI out of all\navailable certificates for any TLS handshake.\n\nSupport: Core";
          type = types.nullOr (submoduleOf "gateway.networking.k8s.io.v1.GatewaySpecListenersTls");
        };
      };

      config = {
        "allowedRoutes" = mkOverride 1002 null;
        "hostname" = mkOverride 1002 null;
        "tls" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1.GatewaySpecListenersAllowedRoutes" = {

      options = {
        "kinds" = mkOption {
          description = "Kinds specifies the groups and kinds of Routes that are allowed to bind\nto this Gateway Listener. When unspecified or empty, the kinds of Routes\nselected are determined using the Listener protocol.\n\nA RouteGroupKind MUST correspond to kinds of Routes that are compatible\nwith the application protocol specified in the Listener's Protocol field.\nIf an implementation does not support or recognize this resource type, it\nMUST set the \"ResolvedRefs\" condition to False for this Listener with the\n\"InvalidRouteKinds\" reason.\n\nSupport: Core";
          type = types.nullOr (
            types.listOf (submoduleOf "gateway.networking.k8s.io.v1.GatewaySpecListenersAllowedRoutesKinds")
          );
        };
        "namespaces" = mkOption {
          description = "Namespaces indicates namespaces from which Routes may be attached to this\nListener. This is restricted to the namespace of this Gateway by default.\n\nSupport: Core";
          type = types.nullOr (
            submoduleOf "gateway.networking.k8s.io.v1.GatewaySpecListenersAllowedRoutesNamespaces"
          );
        };
      };

      config = {
        "kinds" = mkOverride 1002 null;
        "namespaces" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1.GatewaySpecListenersAllowedRoutesKinds" = {

      options = {
        "group" = mkOption {
          description = "Group is the group of the Route.";
          type = types.nullOr types.str;
        };
        "kind" = mkOption {
          description = "Kind is the kind of the Route.";
          type = types.str;
        };
      };

      config = {
        "group" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1.GatewaySpecListenersAllowedRoutesNamespaces" = {

      options = {
        "from" = mkOption {
          description = "From indicates where Routes will be selected for this Gateway. Possible\nvalues are:\n\n* All: Routes in all namespaces may be used by this Gateway.\n* Selector: Routes in namespaces selected by the selector may be used by\n  this Gateway.\n* Same: Only Routes in the same namespace may be used by this Gateway.\n\nSupport: Core";
          type = types.nullOr types.str;
        };
        "selector" = mkOption {
          description = "Selector must be specified when From is set to \"Selector\". In that case,\nonly Routes in Namespaces matching this Selector will be selected by this\nGateway. This field is ignored for other values of \"From\".\n\nSupport: Core";
          type = types.nullOr (
            submoduleOf "gateway.networking.k8s.io.v1.GatewaySpecListenersAllowedRoutesNamespacesSelector"
          );
        };
      };

      config = {
        "from" = mkOverride 1002 null;
        "selector" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1.GatewaySpecListenersAllowedRoutesNamespacesSelector" = {

      options = {
        "matchExpressions" = mkOption {
          description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
          type = types.nullOr (
            types.listOf (
              submoduleOf "gateway.networking.k8s.io.v1.GatewaySpecListenersAllowedRoutesNamespacesSelectorMatchExpressions"
            )
          );
        };
        "matchLabels" = mkOption {
          description = "matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels\nmap is equivalent to an element of matchExpressions, whose key field is \"key\", the\noperator is \"In\", and the values array contains only \"value\". The requirements are ANDed.";
          type = types.nullOr (types.attrsOf types.str);
        };
      };

      config = {
        "matchExpressions" = mkOverride 1002 null;
        "matchLabels" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1.GatewaySpecListenersAllowedRoutesNamespacesSelectorMatchExpressions" =
      {

        options = {
          "key" = mkOption {
            description = "key is the label key that the selector applies to.";
            type = types.str;
          };
          "operator" = mkOption {
            description = "operator represents a key's relationship to a set of values.\nValid operators are In, NotIn, Exists and DoesNotExist.";
            type = types.str;
          };
          "values" = mkOption {
            description = "values is an array of string values. If the operator is In or NotIn,\nthe values array must be non-empty. If the operator is Exists or DoesNotExist,\nthe values array must be empty. This array is replaced during a strategic\nmerge patch.";
            type = types.nullOr (types.listOf types.str);
          };
        };

        config = {
          "values" = mkOverride 1002 null;
        };

      };
    "gateway.networking.k8s.io.v1.GatewaySpecListenersTls" = {

      options = {
        "certificateRefs" = mkOption {
          description = "CertificateRefs contains a series of references to Kubernetes objects that\ncontains TLS certificates and private keys. These certificates are used to\nestablish a TLS handshake for requests that match the hostname of the\nassociated listener.\n\nA single CertificateRef to a Kubernetes Secret has \"Core\" support.\nImplementations MAY choose to support attaching multiple certificates to\na Listener, but this behavior is implementation-specific.\n\nReferences to a resource in different namespace are invalid UNLESS there\nis a ReferenceGrant in the target namespace that allows the certificate\nto be attached. If a ReferenceGrant does not allow this reference, the\n\"ResolvedRefs\" condition MUST be set to False for this listener with the\n\"RefNotPermitted\" reason.\n\nThis field is required to have at least one element when the mode is set\nto \"Terminate\" (default) and is optional otherwise.\n\nCertificateRefs can reference to standard Kubernetes resources, i.e.\nSecret, or implementation-specific custom resources.\n\nSupport: Core - A single reference to a Kubernetes Secret of type kubernetes.io/tls\n\nSupport: Implementation-specific (More than one reference or other resource types)";
          type = types.nullOr (
            coerceAttrsOfSubmodulesToListByKey
              "gateway.networking.k8s.io.v1.GatewaySpecListenersTlsCertificateRefs"
              "name"
              [ ]
          );
          apply = attrsToList;
        };
        "mode" = mkOption {
          description = "Mode defines the TLS behavior for the TLS session initiated by the client.\nThere are two possible modes:\n\n- Terminate: The TLS session between the downstream client and the\n  Gateway is terminated at the Gateway. This mode requires certificates\n  to be specified in some way, such as populating the certificateRefs\n  field.\n- Passthrough: The TLS session is NOT terminated by the Gateway. This\n  implies that the Gateway can't decipher the TLS stream except for\n  the ClientHello message of the TLS protocol. The certificateRefs field\n  is ignored in this mode.\n\nSupport: Core";
          type = types.nullOr types.str;
        };
        "options" = mkOption {
          description = "Options are a list of key/value pairs to enable extended TLS\nconfiguration for each implementation. For example, configuring the\nminimum TLS version or supported cipher suites.\n\nA set of common keys MAY be defined by the API in the future. To avoid\nany ambiguity, implementation-specific definitions MUST use\ndomain-prefixed names, such as `example.com/my-custom-option`.\nUn-prefixed names are reserved for key names defined by Gateway API.\n\nSupport: Implementation-specific";
          type = types.nullOr (types.attrsOf types.str);
        };
      };

      config = {
        "certificateRefs" = mkOverride 1002 null;
        "mode" = mkOverride 1002 null;
        "options" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1.GatewaySpecListenersTlsCertificateRefs" = {

      options = {
        "group" = mkOption {
          description = "Group is the group of the referent. For example, \"gateway.networking.k8s.io\".\nWhen unspecified or empty string, core API group is inferred.";
          type = types.nullOr types.str;
        };
        "kind" = mkOption {
          description = "Kind is kind of the referent. For example \"Secret\".";
          type = types.nullOr types.str;
        };
        "name" = mkOption {
          description = "Name is the name of the referent.";
          type = types.str;
        };
        "namespace" = mkOption {
          description = "Namespace is the namespace of the referenced object. When unspecified, the local\nnamespace is inferred.\n\nNote that when a namespace different than the local namespace is specified,\na ReferenceGrant object is required in the referent namespace to allow that\nnamespace's owner to accept the reference. See the ReferenceGrant\ndocumentation for details.\n\nSupport: Core";
          type = types.nullOr types.str;
        };
      };

      config = {
        "group" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1.GatewayStatus" = {

      options = {
        "addresses" = mkOption {
          description = "Addresses lists the network addresses that have been bound to the\nGateway.\n\nThis list may differ from the addresses provided in the spec under some\nconditions:\n\n  * no addresses are specified, all addresses are dynamically assigned\n  * a combination of specified and dynamic addresses are assigned\n  * a specified address was unusable (e.g. already in use)";
          type = types.nullOr (
            types.listOf (submoduleOf "gateway.networking.k8s.io.v1.GatewayStatusAddresses")
          );
        };
        "conditions" = mkOption {
          description = "Conditions describe the current conditions of the Gateway.\n\nImplementations should prefer to express Gateway conditions\nusing the `GatewayConditionType` and `GatewayConditionReason`\nconstants so that operators and tools can converge on a common\nvocabulary to describe Gateway state.\n\nKnown condition types are:\n\n* \"Accepted\"\n* \"Programmed\"\n* \"Ready\"";
          type = types.nullOr (
            types.listOf (submoduleOf "gateway.networking.k8s.io.v1.GatewayStatusConditions")
          );
        };
        "listeners" = mkOption {
          description = "Listeners provide status for each unique listener port defined in the Spec.";
          type = types.nullOr (
            coerceAttrsOfSubmodulesToListByKey "gateway.networking.k8s.io.v1.GatewayStatusListeners" "name" [
              "name"
            ]
          );
          apply = attrsToList;
        };
      };

      config = {
        "addresses" = mkOverride 1002 null;
        "conditions" = mkOverride 1002 null;
        "listeners" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1.GatewayStatusAddresses" = {

      options = {
        "type" = mkOption {
          description = "Type of the address.";
          type = types.nullOr types.str;
        };
        "value" = mkOption {
          description = "Value of the address. The validity of the values will depend\non the type and support by the controller.\n\nExamples: `1.2.3.4`, `128::1`, `my-ip-address`.";
          type = types.str;
        };
      };

      config = {
        "type" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1.GatewayStatusConditions" = {

      options = {
        "lastTransitionTime" = mkOption {
          description = "lastTransitionTime is the last time the condition transitioned from one status to another.\nThis should be when the underlying condition changed.  If that is not known, then using the time when the API field changed is acceptable.";
          type = types.str;
        };
        "message" = mkOption {
          description = "message is a human readable message indicating details about the transition.\nThis may be an empty string.";
          type = types.str;
        };
        "observedGeneration" = mkOption {
          description = "observedGeneration represents the .metadata.generation that the condition was set based upon.\nFor instance, if .metadata.generation is currently 12, but the .status.conditions[x].observedGeneration is 9, the condition is out of date\nwith respect to the current state of the instance.";
          type = types.nullOr types.int;
        };
        "reason" = mkOption {
          description = "reason contains a programmatic identifier indicating the reason for the condition's last transition.\nProducers of specific condition types may define expected values and meanings for this field,\nand whether the values are considered a guaranteed API.\nThe value should be a CamelCase string.\nThis field may not be empty.";
          type = types.str;
        };
        "status" = mkOption {
          description = "status of the condition, one of True, False, Unknown.";
          type = types.str;
        };
        "type" = mkOption {
          description = "type of condition in CamelCase or in foo.example.com/CamelCase.";
          type = types.str;
        };
      };

      config = {
        "observedGeneration" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1.GatewayStatusListeners" = {

      options = {
        "attachedRoutes" = mkOption {
          description = "AttachedRoutes represents the total number of Routes that have been\nsuccessfully attached to this Listener.\n\nSuccessful attachment of a Route to a Listener is based solely on the\ncombination of the AllowedRoutes field on the corresponding Listener\nand the Route's ParentRefs field. A Route is successfully attached to\na Listener when it is selected by the Listener's AllowedRoutes field\nAND the Route has a valid ParentRef selecting the whole Gateway\nresource or a specific Listener as a parent resource (more detail on\nattachment semantics can be found in the documentation on the various\nRoute kinds ParentRefs fields). Listener or Route status does not impact\nsuccessful attachment, i.e. the AttachedRoutes field count MUST be set\nfor Listeners with condition Accepted: false and MUST count successfully\nattached Routes that may themselves have Accepted: false conditions.\n\nUses for this field include troubleshooting Route attachment and\nmeasuring blast radius/impact of changes to a Listener.";
          type = types.int;
        };
        "conditions" = mkOption {
          description = "Conditions describe the current condition of this listener.";
          type = types.listOf (submoduleOf "gateway.networking.k8s.io.v1.GatewayStatusListenersConditions");
        };
        "name" = mkOption {
          description = "Name is the name of the Listener that this status corresponds to.";
          type = types.str;
        };
        "supportedKinds" = mkOption {
          description = "SupportedKinds is the list indicating the Kinds supported by this\nlistener. This MUST represent the kinds an implementation supports for\nthat Listener configuration.\n\nIf kinds are specified in Spec that are not supported, they MUST NOT\nappear in this list and an implementation MUST set the \"ResolvedRefs\"\ncondition to \"False\" with the \"InvalidRouteKinds\" reason. If both valid\nand invalid Route kinds are specified, the implementation MUST\nreference the valid Route kinds that have been specified.";
          type = types.listOf (
            submoduleOf "gateway.networking.k8s.io.v1.GatewayStatusListenersSupportedKinds"
          );
        };
      };

      config = { };

    };
    "gateway.networking.k8s.io.v1.GatewayStatusListenersConditions" = {

      options = {
        "lastTransitionTime" = mkOption {
          description = "lastTransitionTime is the last time the condition transitioned from one status to another.\nThis should be when the underlying condition changed.  If that is not known, then using the time when the API field changed is acceptable.";
          type = types.str;
        };
        "message" = mkOption {
          description = "message is a human readable message indicating details about the transition.\nThis may be an empty string.";
          type = types.str;
        };
        "observedGeneration" = mkOption {
          description = "observedGeneration represents the .metadata.generation that the condition was set based upon.\nFor instance, if .metadata.generation is currently 12, but the .status.conditions[x].observedGeneration is 9, the condition is out of date\nwith respect to the current state of the instance.";
          type = types.nullOr types.int;
        };
        "reason" = mkOption {
          description = "reason contains a programmatic identifier indicating the reason for the condition's last transition.\nProducers of specific condition types may define expected values and meanings for this field,\nand whether the values are considered a guaranteed API.\nThe value should be a CamelCase string.\nThis field may not be empty.";
          type = types.str;
        };
        "status" = mkOption {
          description = "status of the condition, one of True, False, Unknown.";
          type = types.str;
        };
        "type" = mkOption {
          description = "type of condition in CamelCase or in foo.example.com/CamelCase.";
          type = types.str;
        };
      };

      config = {
        "observedGeneration" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1.GatewayStatusListenersSupportedKinds" = {

      options = {
        "group" = mkOption {
          description = "Group is the group of the Route.";
          type = types.nullOr types.str;
        };
        "kind" = mkOption {
          description = "Kind is the kind of the Route.";
          type = types.str;
        };
      };

      config = {
        "group" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1.HTTPRoute" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object.\nServers should convert recognized schemas to the latest internal value, and\nmay reject unrecognized values.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = types.nullOr types.str;
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents.\nServers may infer this from the endpoint the client submits requests to.\nCannot be updated.\nIn CamelCase.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = types.nullOr types.str;
        };
        "metadata" = mkOption {
          description = "Standard object's metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = types.nullOr (globalSubmoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta");
        };
        "spec" = mkOption {
          description = "Spec defines the desired state of HTTPRoute.";
          type = submoduleOf "gateway.networking.k8s.io.v1.HTTPRouteSpec";
        };
        "status" = mkOption {
          description = "Status defines the current state of HTTPRoute.";
          type = types.nullOr (submoduleOf "gateway.networking.k8s.io.v1.HTTPRouteStatus");
        };
      };

      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1.HTTPRouteSpec" = {

      options = {
        "hostnames" = mkOption {
          description = "Hostnames defines a set of hostnames that should match against the HTTP Host\nheader to select a HTTPRoute used to process the request. Implementations\nMUST ignore any port value specified in the HTTP Host header while\nperforming a match and (absent of any applicable header modification\nconfiguration) MUST forward this header unmodified to the backend.\n\nValid values for Hostnames are determined by RFC 1123 definition of a\nhostname with 2 notable exceptions:\n\n1. IPs are not allowed.\n2. A hostname may be prefixed with a wildcard label (`*.`). The wildcard\n   label must appear by itself as the first label.\n\nIf a hostname is specified by both the Listener and HTTPRoute, there\nmust be at least one intersecting hostname for the HTTPRoute to be\nattached to the Listener. For example:\n\n* A Listener with `test.example.com` as the hostname matches HTTPRoutes\n  that have either not specified any hostnames, or have specified at\n  least one of `test.example.com` or `*.example.com`.\n* A Listener with `*.example.com` as the hostname matches HTTPRoutes\n  that have either not specified any hostnames or have specified at least\n  one hostname that matches the Listener hostname. For example,\n  `*.example.com`, `test.example.com`, and `foo.test.example.com` would\n  all match. On the other hand, `example.com` and `test.example.net` would\n  not match.\n\nHostnames that are prefixed with a wildcard label (`*.`) are interpreted\nas a suffix match. That means that a match for `*.example.com` would match\nboth `test.example.com`, and `foo.test.example.com`, but not `example.com`.\n\nIf both the Listener and HTTPRoute have specified hostnames, any\nHTTPRoute hostnames that do not match the Listener hostname MUST be\nignored. For example, if a Listener specified `*.example.com`, and the\nHTTPRoute specified `test.example.com` and `test.example.net`,\n`test.example.net` must not be considered for a match.\n\nIf both the Listener and HTTPRoute have specified hostnames, and none\nmatch with the criteria above, then the HTTPRoute is not accepted. The\nimplementation must raise an 'Accepted' Condition with a status of\n`False` in the corresponding RouteParentStatus.\n\nIn the event that multiple HTTPRoutes specify intersecting hostnames (e.g.\noverlapping wildcard matching and exact matching hostnames), precedence must\nbe given to rules from the HTTPRoute with the largest number of:\n\n* Characters in a matching non-wildcard hostname.\n* Characters in a matching hostname.\n\nIf ties exist across multiple Routes, the matching precedence rules for\nHTTPRouteMatches takes over.\n\nSupport: Core";
          type = types.nullOr (types.listOf types.str);
        };
        "parentRefs" = mkOption {
          description = "ParentRefs references the resources (usually Gateways) that a Route wants\nto be attached to. Note that the referenced parent resource needs to\nallow this for the attachment to be complete. For Gateways, that means\nthe Gateway needs to allow attachment from Routes of this kind and\nnamespace. For Services, that means the Service must either be in the same\nnamespace for a \"producer\" route, or the mesh implementation must support\nand allow \"consumer\" routes for the referenced Service. ReferenceGrant is\nnot applicable for governing ParentRefs to Services - it is not possible to\ncreate a \"producer\" route for a Service in a different namespace from the\nRoute.\n\nThere are two kinds of parent resources with \"Core\" support:\n\n* Gateway (Gateway conformance profile)\n* Service (Mesh conformance profile, ClusterIP Services only)\n\nThis API may be extended in the future to support additional kinds of parent\nresources.\n\nParentRefs must be _distinct_. This means either that:\n\n* They select different objects.  If this is the case, then parentRef\n  entries are distinct. In terms of fields, this means that the\n  multi-part key defined by `group`, `kind`, `namespace`, and `name` must\n  be unique across all parentRef entries in the Route.\n* They do not select different objects, but for each optional field used,\n  each ParentRef that selects the same object must set the same set of\n  optional fields to different values. If one ParentRef sets a\n  combination of optional fields, all must set the same combination.\n\nSome examples:\n\n* If one ParentRef sets `sectionName`, all ParentRefs referencing the\n  same object must also set `sectionName`.\n* If one ParentRef sets `port`, all ParentRefs referencing the same\n  object must also set `port`.\n* If one ParentRef sets `sectionName` and `port`, all ParentRefs\n  referencing the same object must also set `sectionName` and `port`.\n\nIt is possible to separately reference multiple distinct objects that may\nbe collapsed by an implementation. For example, some implementations may\nchoose to merge compatible Gateway Listeners together. If that is the\ncase, the list of routes attached to those resources should also be\nmerged.\n\nNote that for ParentRefs that cross namespace boundaries, there are specific\nrules. Cross-namespace references are only valid if they are explicitly\nallowed by something in the namespace they are referring to. For example,\nGateway has the AllowedRoutes field, and ReferenceGrant provides a\ngeneric way to enable other kinds of cross-namespace reference.";
          type = types.nullOr (
            coerceAttrsOfSubmodulesToListByKey "gateway.networking.k8s.io.v1.HTTPRouteSpecParentRefs" "name" [ ]
          );
          apply = attrsToList;
        };
        "rules" = mkOption {
          description = "Rules are a list of HTTP matchers, filters and actions.";
          type = types.nullOr (
            coerceAttrsOfSubmodulesToListByKey "gateway.networking.k8s.io.v1.HTTPRouteSpecRules" "name" [ ]
          );
          apply = attrsToList;
        };
      };

      config = {
        "hostnames" = mkOverride 1002 null;
        "parentRefs" = mkOverride 1002 null;
        "rules" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1.HTTPRouteSpecParentRefs" = {

      options = {
        "group" = mkOption {
          description = "Group is the group of the referent.\nWhen unspecified, \"gateway.networking.k8s.io\" is inferred.\nTo set the core API group (such as for a \"Service\" kind referent),\nGroup must be explicitly set to \"\" (empty string).\n\nSupport: Core";
          type = types.nullOr types.str;
        };
        "kind" = mkOption {
          description = "Kind is kind of the referent.\n\nThere are two kinds of parent resources with \"Core\" support:\n\n* Gateway (Gateway conformance profile)\n* Service (Mesh conformance profile, ClusterIP Services only)\n\nSupport for other resources is Implementation-Specific.";
          type = types.nullOr types.str;
        };
        "name" = mkOption {
          description = "Name is the name of the referent.\n\nSupport: Core";
          type = types.str;
        };
        "namespace" = mkOption {
          description = "Namespace is the namespace of the referent. When unspecified, this refers\nto the local namespace of the Route.\n\nNote that there are specific rules for ParentRefs which cross namespace\nboundaries. Cross-namespace references are only valid if they are explicitly\nallowed by something in the namespace they are referring to. For example:\nGateway has the AllowedRoutes field, and ReferenceGrant provides a\ngeneric way to enable any other kind of cross-namespace reference.\n\nSupport: Core";
          type = types.nullOr types.str;
        };
        "port" = mkOption {
          description = "Port is the network port this Route targets. It can be interpreted\ndifferently based on the type of parent resource.\n\nWhen the parent resource is a Gateway, this targets all listeners\nlistening on the specified port that also support this kind of Route(and\nselect this Route). It's not recommended to set `Port` unless the\nnetworking behaviors specified in a Route must apply to a specific port\nas opposed to a listener(s) whose port(s) may be changed. When both Port\nand SectionName are specified, the name and port of the selected listener\nmust match both specified values.\n\nImplementations MAY choose to support other parent resources.\nImplementations supporting other types of parent resources MUST clearly\ndocument how/if Port is interpreted.\n\nFor the purpose of status, an attachment is considered successful as\nlong as the parent resource accepts it partially. For example, Gateway\nlisteners can restrict which Routes can attach to them by Route kind,\nnamespace, or hostname. If 1 of 2 Gateway listeners accept attachment\nfrom the referencing Route, the Route MUST be considered successfully\nattached. If no Gateway listeners accept attachment from this Route,\nthe Route MUST be considered detached from the Gateway.\n\nSupport: Extended";
          type = types.nullOr types.int;
        };
        "sectionName" = mkOption {
          description = "SectionName is the name of a section within the target resource. In the\nfollowing resources, SectionName is interpreted as the following:\n\n* Gateway: Listener name. When both Port (experimental) and SectionName\nare specified, the name and port of the selected listener must match\nboth specified values.\n* Service: Port name. When both Port (experimental) and SectionName\nare specified, the name and port of the selected listener must match\nboth specified values.\n\nImplementations MAY choose to support attaching Routes to other resources.\nIf that is the case, they MUST clearly document how SectionName is\ninterpreted.\n\nWhen unspecified (empty string), this will reference the entire resource.\nFor the purpose of status, an attachment is considered successful if at\nleast one section in the parent resource accepts it. For example, Gateway\nlisteners can restrict which Routes can attach to them by Route kind,\nnamespace, or hostname. If 1 of 2 Gateway listeners accept attachment from\nthe referencing Route, the Route MUST be considered successfully\nattached. If no Gateway listeners accept attachment from this Route, the\nRoute MUST be considered detached from the Gateway.\n\nSupport: Core";
          type = types.nullOr types.str;
        };
      };

      config = {
        "group" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
        "port" = mkOverride 1002 null;
        "sectionName" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1.HTTPRouteSpecRules" = {

      options = {
        "backendRefs" = mkOption {
          description = "BackendRefs defines the backend(s) where matching requests should be\nsent.\n\nFailure behavior here depends on how many BackendRefs are specified and\nhow many are invalid.\n\nIf *all* entries in BackendRefs are invalid, and there are also no filters\nspecified in this route rule, *all* traffic which matches this rule MUST\nreceive a 500 status code.\n\nSee the HTTPBackendRef definition for the rules about what makes a single\nHTTPBackendRef invalid.\n\nWhen a HTTPBackendRef is invalid, 500 status codes MUST be returned for\nrequests that would have otherwise been routed to an invalid backend. If\nmultiple backends are specified, and some are invalid, the proportion of\nrequests that would otherwise have been routed to an invalid backend\nMUST receive a 500 status code.\n\nFor example, if two backends are specified with equal weights, and one is\ninvalid, 50 percent of traffic must receive a 500. Implementations may\nchoose how that 50 percent is determined.\n\nWhen a HTTPBackendRef refers to a Service that has no ready endpoints,\nimplementations SHOULD return a 503 for requests to that backend instead.\nIf an implementation chooses to do this, all of the above rules for 500 responses\nMUST also apply for responses that return a 503.\n\nSupport: Core for Kubernetes Service\n\nSupport: Extended for Kubernetes ServiceImport\n\nSupport: Implementation-specific for any other resource\n\nSupport for weight: Core";
          type = types.nullOr (
            coerceAttrsOfSubmodulesToListByKey "gateway.networking.k8s.io.v1.HTTPRouteSpecRulesBackendRefs"
              "name"
              [ ]
          );
          apply = attrsToList;
        };
        "filters" = mkOption {
          description = "Filters define the filters that are applied to requests that match\nthis rule.\n\nWherever possible, implementations SHOULD implement filters in the order\nthey are specified.\n\nImplementations MAY choose to implement this ordering strictly, rejecting\nany combination or order of filters that cannot be supported. If implementations\nchoose a strict interpretation of filter ordering, they MUST clearly document\nthat behavior.\n\nTo reject an invalid combination or order of filters, implementations SHOULD\nconsider the Route Rules with this configuration invalid. If all Route Rules\nin a Route are invalid, the entire Route would be considered invalid. If only\na portion of Route Rules are invalid, implementations MUST set the\n\"PartiallyInvalid\" condition for the Route.\n\nConformance-levels at this level are defined based on the type of filter:\n\n- ALL core filters MUST be supported by all implementations.\n- Implementers are encouraged to support extended filters.\n- Implementation-specific custom filters have no API guarantees across\n  implementations.\n\nSpecifying the same filter multiple times is not supported unless explicitly\nindicated in the filter.\n\nAll filters are expected to be compatible with each other except for the\nURLRewrite and RequestRedirect filters, which may not be combined. If an\nimplementation cannot support other combinations of filters, they must clearly\ndocument that limitation. In cases where incompatible or unsupported\nfilters are specified and cause the `Accepted` condition to be set to status\n`False`, implementations may use the `IncompatibleFilters` reason to specify\nthis configuration error.\n\nSupport: Core";
          type = types.nullOr (
            types.listOf (submoduleOf "gateway.networking.k8s.io.v1.HTTPRouteSpecRulesFilters")
          );
        };
        "matches" = mkOption {
          description = "Matches define conditions used for matching the rule against incoming\nHTTP requests. Each match is independent, i.e. this rule will be matched\nif **any** one of the matches is satisfied.\n\nFor example, take the following matches configuration:\n\n```\nmatches:\n- path:\n    value: \"/foo\"\n  headers:\n  - name: \"version\"\n    value: \"v2\"\n- path:\n    value: \"/v2/foo\"\n```\n\nFor a request to match against this rule, a request must satisfy\nEITHER of the two conditions:\n\n- path prefixed with `/foo` AND contains the header `version: v2`\n- path prefix of `/v2/foo`\n\nSee the documentation for HTTPRouteMatch on how to specify multiple\nmatch conditions that should be ANDed together.\n\nIf no matches are specified, the default is a prefix\npath match on \"/\", which has the effect of matching every\nHTTP request.\n\nProxy or Load Balancer routing configuration generated from HTTPRoutes\nMUST prioritize matches based on the following criteria, continuing on\nties. Across all rules specified on applicable Routes, precedence must be\ngiven to the match having:\n\n* \"Exact\" path match.\n* \"Prefix\" path match with largest number of characters.\n* Method match.\n* Largest number of header matches.\n* Largest number of query param matches.\n\nNote: The precedence of RegularExpression path matches are implementation-specific.\n\nIf ties still exist across multiple Routes, matching precedence MUST be\ndetermined in order of the following criteria, continuing on ties:\n\n* The oldest Route based on creation timestamp.\n* The Route appearing first in alphabetical order by\n  \"{namespace}/{name}\".\n\nIf ties still exist within an HTTPRoute, matching precedence MUST be granted\nto the FIRST matching rule (in list order) with a match meeting the above\ncriteria.\n\nWhen no rules matching a request have been successfully attached to the\nparent a request is coming from, a HTTP 404 status code MUST be returned.";
          type = types.nullOr (
            types.listOf (submoduleOf "gateway.networking.k8s.io.v1.HTTPRouteSpecRulesMatches")
          );
        };
        "name" = mkOption {
          description = "Name is the name of the route rule. This name MUST be unique within a Route if it is set.\n\nSupport: Extended";
          type = types.nullOr types.str;
        };
        "timeouts" = mkOption {
          description = "Timeouts defines the timeouts that can be configured for an HTTP request.\n\nSupport: Extended";
          type = types.nullOr (submoduleOf "gateway.networking.k8s.io.v1.HTTPRouteSpecRulesTimeouts");
        };
      };

      config = {
        "backendRefs" = mkOverride 1002 null;
        "filters" = mkOverride 1002 null;
        "matches" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "timeouts" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1.HTTPRouteSpecRulesBackendRefs" = {

      options = {
        "filters" = mkOption {
          description = "Filters defined at this level should be executed if and only if the\nrequest is being forwarded to the backend defined here.\n\nSupport: Implementation-specific (For broader support of filters, use the\nFilters field in HTTPRouteRule.)";
          type = types.nullOr (
            types.listOf (submoduleOf "gateway.networking.k8s.io.v1.HTTPRouteSpecRulesBackendRefsFilters")
          );
        };
        "group" = mkOption {
          description = "Group is the group of the referent. For example, \"gateway.networking.k8s.io\".\nWhen unspecified or empty string, core API group is inferred.";
          type = types.nullOr types.str;
        };
        "kind" = mkOption {
          description = "Kind is the Kubernetes resource kind of the referent. For example\n\"Service\".\n\nDefaults to \"Service\" when not specified.\n\nExternalName services can refer to CNAME DNS records that may live\noutside of the cluster and as such are difficult to reason about in\nterms of conformance. They also may not be safe to forward to (see\nCVE-2021-25740 for more information). Implementations SHOULD NOT\nsupport ExternalName Services.\n\nSupport: Core (Services with a type other than ExternalName)\n\nSupport: Implementation-specific (Services with type ExternalName)";
          type = types.nullOr types.str;
        };
        "name" = mkOption {
          description = "Name is the name of the referent.";
          type = types.str;
        };
        "namespace" = mkOption {
          description = "Namespace is the namespace of the backend. When unspecified, the local\nnamespace is inferred.\n\nNote that when a namespace different than the local namespace is specified,\na ReferenceGrant object is required in the referent namespace to allow that\nnamespace's owner to accept the reference. See the ReferenceGrant\ndocumentation for details.\n\nSupport: Core";
          type = types.nullOr types.str;
        };
        "port" = mkOption {
          description = "Port specifies the destination port number to use for this resource.\nPort is required when the referent is a Kubernetes Service. In this\ncase, the port number is the service port number, not the target port.\nFor other resources, destination port might be derived from the referent\nresource or this field.";
          type = types.nullOr types.int;
        };
        "weight" = mkOption {
          description = "Weight specifies the proportion of requests forwarded to the referenced\nbackend. This is computed as weight/(sum of all weights in this\nBackendRefs list). For non-zero values, there may be some epsilon from\nthe exact proportion defined here depending on the precision an\nimplementation supports. Weight is not a percentage and the sum of\nweights does not need to equal 100.\n\nIf only one backend is specified and it has a weight greater than 0, 100%\nof the traffic is forwarded to that backend. If weight is set to 0, no\ntraffic should be forwarded for this entry. If unspecified, weight\ndefaults to 1.\n\nSupport for this field varies based on the context where used.";
          type = types.nullOr types.int;
        };
      };

      config = {
        "filters" = mkOverride 1002 null;
        "group" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
        "port" = mkOverride 1002 null;
        "weight" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1.HTTPRouteSpecRulesBackendRefsFilters" = {

      options = {
        "extensionRef" = mkOption {
          description = "ExtensionRef is an optional, implementation-specific extension to the\n\"filter\" behavior.  For example, resource \"myroutefilter\" in group\n\"networking.example.net\"). ExtensionRef MUST NOT be used for core and\nextended filters.\n\nThis filter can be used multiple times within the same rule.\n\nSupport: Implementation-specific";
          type = types.nullOr (
            submoduleOf "gateway.networking.k8s.io.v1.HTTPRouteSpecRulesBackendRefsFiltersExtensionRef"
          );
        };
        "requestHeaderModifier" = mkOption {
          description = "RequestHeaderModifier defines a schema for a filter that modifies request\nheaders.\n\nSupport: Core";
          type = types.nullOr (
            submoduleOf "gateway.networking.k8s.io.v1.HTTPRouteSpecRulesBackendRefsFiltersRequestHeaderModifier"
          );
        };
        "requestMirror" = mkOption {
          description = "RequestMirror defines a schema for a filter that mirrors requests.\nRequests are sent to the specified destination, but responses from\nthat destination are ignored.\n\nThis filter can be used multiple times within the same rule. Note that\nnot all implementations will be able to support mirroring to multiple\nbackends.\n\nSupport: Extended";
          type = types.nullOr (
            submoduleOf "gateway.networking.k8s.io.v1.HTTPRouteSpecRulesBackendRefsFiltersRequestMirror"
          );
        };
        "requestRedirect" = mkOption {
          description = "RequestRedirect defines a schema for a filter that responds to the\nrequest with an HTTP redirection.\n\nSupport: Core";
          type = types.nullOr (
            submoduleOf "gateway.networking.k8s.io.v1.HTTPRouteSpecRulesBackendRefsFiltersRequestRedirect"
          );
        };
        "responseHeaderModifier" = mkOption {
          description = "ResponseHeaderModifier defines a schema for a filter that modifies response\nheaders.\n\nSupport: Extended";
          type = types.nullOr (
            submoduleOf "gateway.networking.k8s.io.v1.HTTPRouteSpecRulesBackendRefsFiltersResponseHeaderModifier"
          );
        };
        "type" = mkOption {
          description = "Type identifies the type of filter to apply. As with other API fields,\ntypes are classified into three conformance levels:\n\n- Core: Filter types and their corresponding configuration defined by\n  \"Support: Core\" in this package, e.g. \"RequestHeaderModifier\". All\n  implementations must support core filters.\n\n- Extended: Filter types and their corresponding configuration defined by\n  \"Support: Extended\" in this package, e.g. \"RequestMirror\". Implementers\n  are encouraged to support extended filters.\n\n- Implementation-specific: Filters that are defined and supported by\n  specific vendors.\n  In the future, filters showing convergence in behavior across multiple\n  implementations will be considered for inclusion in extended or core\n  conformance levels. Filter-specific configuration for such filters\n  is specified using the ExtensionRef field. `Type` should be set to\n  \"ExtensionRef\" for custom filters.\n\nImplementers are encouraged to define custom implementation types to\nextend the core API with implementation-specific behavior.\n\nIf a reference to a custom filter type cannot be resolved, the filter\nMUST NOT be skipped. Instead, requests that would have been processed by\nthat filter MUST receive a HTTP error response.\n\nNote that values may be added to this enum, implementations\nmust ensure that unknown values will not cause a crash.\n\nUnknown values here must result in the implementation setting the\nAccepted Condition for the Route to `status: False`, with a\nReason of `UnsupportedValue`.";
          type = types.str;
        };
        "urlRewrite" = mkOption {
          description = "URLRewrite defines a schema for a filter that modifies a request during forwarding.\n\nSupport: Extended";
          type = types.nullOr (
            submoduleOf "gateway.networking.k8s.io.v1.HTTPRouteSpecRulesBackendRefsFiltersUrlRewrite"
          );
        };
      };

      config = {
        "extensionRef" = mkOverride 1002 null;
        "requestHeaderModifier" = mkOverride 1002 null;
        "requestMirror" = mkOverride 1002 null;
        "requestRedirect" = mkOverride 1002 null;
        "responseHeaderModifier" = mkOverride 1002 null;
        "urlRewrite" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1.HTTPRouteSpecRulesBackendRefsFiltersExtensionRef" = {

      options = {
        "group" = mkOption {
          description = "Group is the group of the referent. For example, \"gateway.networking.k8s.io\".\nWhen unspecified or empty string, core API group is inferred.";
          type = types.str;
        };
        "kind" = mkOption {
          description = "Kind is kind of the referent. For example \"HTTPRoute\" or \"Service\".";
          type = types.str;
        };
        "name" = mkOption {
          description = "Name is the name of the referent.";
          type = types.str;
        };
      };

      config = { };

    };
    "gateway.networking.k8s.io.v1.HTTPRouteSpecRulesBackendRefsFiltersRequestHeaderModifier" = {

      options = {
        "add" = mkOption {
          description = "Add adds the given header(s) (name, value) to the request\nbefore the action. It appends to any existing values associated\nwith the header name.\n\nInput:\n  GET /foo HTTP/1.1\n  my-header: foo\n\nConfig:\n  add:\n  - name: \"my-header\"\n    value: \"bar,baz\"\n\nOutput:\n  GET /foo HTTP/1.1\n  my-header: foo,bar,baz";
          type = types.nullOr (
            coerceAttrsOfSubmodulesToListByKey
              "gateway.networking.k8s.io.v1.HTTPRouteSpecRulesBackendRefsFiltersRequestHeaderModifierAdd"
              "name"
              [ "name" ]
          );
          apply = attrsToList;
        };
        "remove" = mkOption {
          description = "Remove the given header(s) from the HTTP request before the action. The\nvalue of Remove is a list of HTTP header names. Note that the header\nnames are case-insensitive (see\nhttps://datatracker.ietf.org/doc/html/rfc2616#section-4.2).\n\nInput:\n  GET /foo HTTP/1.1\n  my-header1: foo\n  my-header2: bar\n  my-header3: baz\n\nConfig:\n  remove: [\"my-header1\", \"my-header3\"]\n\nOutput:\n  GET /foo HTTP/1.1\n  my-header2: bar";
          type = types.nullOr (types.listOf types.str);
        };
        "set" = mkOption {
          description = "Set overwrites the request with the given header (name, value)\nbefore the action.\n\nInput:\n  GET /foo HTTP/1.1\n  my-header: foo\n\nConfig:\n  set:\n  - name: \"my-header\"\n    value: \"bar\"\n\nOutput:\n  GET /foo HTTP/1.1\n  my-header: bar";
          type = types.nullOr (
            coerceAttrsOfSubmodulesToListByKey
              "gateway.networking.k8s.io.v1.HTTPRouteSpecRulesBackendRefsFiltersRequestHeaderModifierSet"
              "name"
              [ "name" ]
          );
          apply = attrsToList;
        };
      };

      config = {
        "add" = mkOverride 1002 null;
        "remove" = mkOverride 1002 null;
        "set" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1.HTTPRouteSpecRulesBackendRefsFiltersRequestHeaderModifierAdd" = {

      options = {
        "name" = mkOption {
          description = "Name is the name of the HTTP Header to be matched. Name matching MUST be\ncase-insensitive. (See https://tools.ietf.org/html/rfc7230#section-3.2).\n\nIf multiple entries specify equivalent header names, the first entry with\nan equivalent name MUST be considered for a match. Subsequent entries\nwith an equivalent header name MUST be ignored. Due to the\ncase-insensitivity of header names, \"foo\" and \"Foo\" are considered\nequivalent.";
          type = types.str;
        };
        "value" = mkOption {
          description = "Value is the value of HTTP Header to be matched.";
          type = types.str;
        };
      };

      config = { };

    };
    "gateway.networking.k8s.io.v1.HTTPRouteSpecRulesBackendRefsFiltersRequestHeaderModifierSet" = {

      options = {
        "name" = mkOption {
          description = "Name is the name of the HTTP Header to be matched. Name matching MUST be\ncase-insensitive. (See https://tools.ietf.org/html/rfc7230#section-3.2).\n\nIf multiple entries specify equivalent header names, the first entry with\nan equivalent name MUST be considered for a match. Subsequent entries\nwith an equivalent header name MUST be ignored. Due to the\ncase-insensitivity of header names, \"foo\" and \"Foo\" are considered\nequivalent.";
          type = types.str;
        };
        "value" = mkOption {
          description = "Value is the value of HTTP Header to be matched.";
          type = types.str;
        };
      };

      config = { };

    };
    "gateway.networking.k8s.io.v1.HTTPRouteSpecRulesBackendRefsFiltersRequestMirror" = {

      options = {
        "backendRef" = mkOption {
          description = "BackendRef references a resource where mirrored requests are sent.\n\nMirrored requests must be sent only to a single destination endpoint\nwithin this BackendRef, irrespective of how many endpoints are present\nwithin this BackendRef.\n\nIf the referent cannot be found, this BackendRef is invalid and must be\ndropped from the Gateway. The controller must ensure the \"ResolvedRefs\"\ncondition on the Route status is set to `status: False` and not configure\nthis backend in the underlying implementation.\n\nIf there is a cross-namespace reference to an *existing* object\nthat is not allowed by a ReferenceGrant, the controller must ensure the\n\"ResolvedRefs\"  condition on the Route is set to `status: False`,\nwith the \"RefNotPermitted\" reason and not configure this backend in the\nunderlying implementation.\n\nIn either error case, the Message of the `ResolvedRefs` Condition\nshould be used to provide more detail about the problem.\n\nSupport: Extended for Kubernetes Service\n\nSupport: Implementation-specific for any other resource";
          type = submoduleOf "gateway.networking.k8s.io.v1.HTTPRouteSpecRulesBackendRefsFiltersRequestMirrorBackendRef";
        };
        "fraction" = mkOption {
          description = "Fraction represents the fraction of requests that should be\nmirrored to BackendRef.\n\nOnly one of Fraction or Percent may be specified. If neither field\nis specified, 100% of requests will be mirrored.";
          type = types.nullOr (
            submoduleOf "gateway.networking.k8s.io.v1.HTTPRouteSpecRulesBackendRefsFiltersRequestMirrorFraction"
          );
        };
        "percent" = mkOption {
          description = "Percent represents the percentage of requests that should be\nmirrored to BackendRef. Its minimum value is 0 (indicating 0% of\nrequests) and its maximum value is 100 (indicating 100% of requests).\n\nOnly one of Fraction or Percent may be specified. If neither field\nis specified, 100% of requests will be mirrored.";
          type = types.nullOr types.int;
        };
      };

      config = {
        "fraction" = mkOverride 1002 null;
        "percent" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1.HTTPRouteSpecRulesBackendRefsFiltersRequestMirrorBackendRef" = {

      options = {
        "group" = mkOption {
          description = "Group is the group of the referent. For example, \"gateway.networking.k8s.io\".\nWhen unspecified or empty string, core API group is inferred.";
          type = types.nullOr types.str;
        };
        "kind" = mkOption {
          description = "Kind is the Kubernetes resource kind of the referent. For example\n\"Service\".\n\nDefaults to \"Service\" when not specified.\n\nExternalName services can refer to CNAME DNS records that may live\noutside of the cluster and as such are difficult to reason about in\nterms of conformance. They also may not be safe to forward to (see\nCVE-2021-25740 for more information). Implementations SHOULD NOT\nsupport ExternalName Services.\n\nSupport: Core (Services with a type other than ExternalName)\n\nSupport: Implementation-specific (Services with type ExternalName)";
          type = types.nullOr types.str;
        };
        "name" = mkOption {
          description = "Name is the name of the referent.";
          type = types.str;
        };
        "namespace" = mkOption {
          description = "Namespace is the namespace of the backend. When unspecified, the local\nnamespace is inferred.\n\nNote that when a namespace different than the local namespace is specified,\na ReferenceGrant object is required in the referent namespace to allow that\nnamespace's owner to accept the reference. See the ReferenceGrant\ndocumentation for details.\n\nSupport: Core";
          type = types.nullOr types.str;
        };
        "port" = mkOption {
          description = "Port specifies the destination port number to use for this resource.\nPort is required when the referent is a Kubernetes Service. In this\ncase, the port number is the service port number, not the target port.\nFor other resources, destination port might be derived from the referent\nresource or this field.";
          type = types.nullOr types.int;
        };
      };

      config = {
        "group" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
        "port" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1.HTTPRouteSpecRulesBackendRefsFiltersRequestMirrorFraction" = {

      options = {
        "denominator" = mkOption {
          description = "";
          type = types.nullOr types.int;
        };
        "numerator" = mkOption {
          description = "";
          type = types.int;
        };
      };

      config = {
        "denominator" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1.HTTPRouteSpecRulesBackendRefsFiltersRequestRedirect" = {

      options = {
        "hostname" = mkOption {
          description = "Hostname is the hostname to be used in the value of the `Location`\nheader in the response.\nWhen empty, the hostname in the `Host` header of the request is used.\n\nSupport: Core";
          type = types.nullOr types.str;
        };
        "path" = mkOption {
          description = "Path defines parameters used to modify the path of the incoming request.\nThe modified path is then used to construct the `Location` header. When\nempty, the request path is used as-is.\n\nSupport: Extended";
          type = types.nullOr (
            submoduleOf "gateway.networking.k8s.io.v1.HTTPRouteSpecRulesBackendRefsFiltersRequestRedirectPath"
          );
        };
        "port" = mkOption {
          description = "Port is the port to be used in the value of the `Location`\nheader in the response.\n\nIf no port is specified, the redirect port MUST be derived using the\nfollowing rules:\n\n* If redirect scheme is not-empty, the redirect port MUST be the well-known\n  port associated with the redirect scheme. Specifically \"http\" to port 80\n  and \"https\" to port 443. If the redirect scheme does not have a\n  well-known port, the listener port of the Gateway SHOULD be used.\n* If redirect scheme is empty, the redirect port MUST be the Gateway\n  Listener port.\n\nImplementations SHOULD NOT add the port number in the 'Location'\nheader in the following cases:\n\n* A Location header that will use HTTP (whether that is determined via\n  the Listener protocol or the Scheme field) _and_ use port 80.\n* A Location header that will use HTTPS (whether that is determined via\n  the Listener protocol or the Scheme field) _and_ use port 443.\n\nSupport: Extended";
          type = types.nullOr types.int;
        };
        "scheme" = mkOption {
          description = "Scheme is the scheme to be used in the value of the `Location` header in\nthe response. When empty, the scheme of the request is used.\n\nScheme redirects can affect the port of the redirect, for more information,\nrefer to the documentation for the port field of this filter.\n\nNote that values may be added to this enum, implementations\nmust ensure that unknown values will not cause a crash.\n\nUnknown values here must result in the implementation setting the\nAccepted Condition for the Route to `status: False`, with a\nReason of `UnsupportedValue`.\n\nSupport: Extended";
          type = types.nullOr types.str;
        };
        "statusCode" = mkOption {
          description = "StatusCode is the HTTP status code to be used in response.\n\nNote that values may be added to this enum, implementations\nmust ensure that unknown values will not cause a crash.\n\nUnknown values here must result in the implementation setting the\nAccepted Condition for the Route to `status: False`, with a\nReason of `UnsupportedValue`.\n\nSupport: Core";
          type = types.nullOr types.int;
        };
      };

      config = {
        "hostname" = mkOverride 1002 null;
        "path" = mkOverride 1002 null;
        "port" = mkOverride 1002 null;
        "scheme" = mkOverride 1002 null;
        "statusCode" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1.HTTPRouteSpecRulesBackendRefsFiltersRequestRedirectPath" = {

      options = {
        "replaceFullPath" = mkOption {
          description = "ReplaceFullPath specifies the value with which to replace the full path\nof a request during a rewrite or redirect.";
          type = types.nullOr types.str;
        };
        "replacePrefixMatch" = mkOption {
          description = "ReplacePrefixMatch specifies the value with which to replace the prefix\nmatch of a request during a rewrite or redirect. For example, a request\nto \"/foo/bar\" with a prefix match of \"/foo\" and a ReplacePrefixMatch\nof \"/xyz\" would be modified to \"/xyz/bar\".\n\nNote that this matches the behavior of the PathPrefix match type. This\nmatches full path elements. A path element refers to the list of labels\nin the path split by the `/` separator. When specified, a trailing `/` is\nignored. For example, the paths `/abc`, `/abc/`, and `/abc/def` would all\nmatch the prefix `/abc`, but the path `/abcd` would not.\n\nReplacePrefixMatch is only compatible with a `PathPrefix` HTTPRouteMatch.\nUsing any other HTTPRouteMatch type on the same HTTPRouteRule will result in\nthe implementation setting the Accepted Condition for the Route to `status: False`.\n\nRequest Path | Prefix Match | Replace Prefix | Modified Path";
          type = types.nullOr types.str;
        };
        "type" = mkOption {
          description = "Type defines the type of path modifier. Additional types may be\nadded in a future release of the API.\n\nNote that values may be added to this enum, implementations\nmust ensure that unknown values will not cause a crash.\n\nUnknown values here must result in the implementation setting the\nAccepted Condition for the Route to `status: False`, with a\nReason of `UnsupportedValue`.";
          type = types.str;
        };
      };

      config = {
        "replaceFullPath" = mkOverride 1002 null;
        "replacePrefixMatch" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1.HTTPRouteSpecRulesBackendRefsFiltersResponseHeaderModifier" = {

      options = {
        "add" = mkOption {
          description = "Add adds the given header(s) (name, value) to the request\nbefore the action. It appends to any existing values associated\nwith the header name.\n\nInput:\n  GET /foo HTTP/1.1\n  my-header: foo\n\nConfig:\n  add:\n  - name: \"my-header\"\n    value: \"bar,baz\"\n\nOutput:\n  GET /foo HTTP/1.1\n  my-header: foo,bar,baz";
          type = types.nullOr (
            coerceAttrsOfSubmodulesToListByKey
              "gateway.networking.k8s.io.v1.HTTPRouteSpecRulesBackendRefsFiltersResponseHeaderModifierAdd"
              "name"
              [ "name" ]
          );
          apply = attrsToList;
        };
        "remove" = mkOption {
          description = "Remove the given header(s) from the HTTP request before the action. The\nvalue of Remove is a list of HTTP header names. Note that the header\nnames are case-insensitive (see\nhttps://datatracker.ietf.org/doc/html/rfc2616#section-4.2).\n\nInput:\n  GET /foo HTTP/1.1\n  my-header1: foo\n  my-header2: bar\n  my-header3: baz\n\nConfig:\n  remove: [\"my-header1\", \"my-header3\"]\n\nOutput:\n  GET /foo HTTP/1.1\n  my-header2: bar";
          type = types.nullOr (types.listOf types.str);
        };
        "set" = mkOption {
          description = "Set overwrites the request with the given header (name, value)\nbefore the action.\n\nInput:\n  GET /foo HTTP/1.1\n  my-header: foo\n\nConfig:\n  set:\n  - name: \"my-header\"\n    value: \"bar\"\n\nOutput:\n  GET /foo HTTP/1.1\n  my-header: bar";
          type = types.nullOr (
            coerceAttrsOfSubmodulesToListByKey
              "gateway.networking.k8s.io.v1.HTTPRouteSpecRulesBackendRefsFiltersResponseHeaderModifierSet"
              "name"
              [ "name" ]
          );
          apply = attrsToList;
        };
      };

      config = {
        "add" = mkOverride 1002 null;
        "remove" = mkOverride 1002 null;
        "set" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1.HTTPRouteSpecRulesBackendRefsFiltersResponseHeaderModifierAdd" = {

      options = {
        "name" = mkOption {
          description = "Name is the name of the HTTP Header to be matched. Name matching MUST be\ncase-insensitive. (See https://tools.ietf.org/html/rfc7230#section-3.2).\n\nIf multiple entries specify equivalent header names, the first entry with\nan equivalent name MUST be considered for a match. Subsequent entries\nwith an equivalent header name MUST be ignored. Due to the\ncase-insensitivity of header names, \"foo\" and \"Foo\" are considered\nequivalent.";
          type = types.str;
        };
        "value" = mkOption {
          description = "Value is the value of HTTP Header to be matched.";
          type = types.str;
        };
      };

      config = { };

    };
    "gateway.networking.k8s.io.v1.HTTPRouteSpecRulesBackendRefsFiltersResponseHeaderModifierSet" = {

      options = {
        "name" = mkOption {
          description = "Name is the name of the HTTP Header to be matched. Name matching MUST be\ncase-insensitive. (See https://tools.ietf.org/html/rfc7230#section-3.2).\n\nIf multiple entries specify equivalent header names, the first entry with\nan equivalent name MUST be considered for a match. Subsequent entries\nwith an equivalent header name MUST be ignored. Due to the\ncase-insensitivity of header names, \"foo\" and \"Foo\" are considered\nequivalent.";
          type = types.str;
        };
        "value" = mkOption {
          description = "Value is the value of HTTP Header to be matched.";
          type = types.str;
        };
      };

      config = { };

    };
    "gateway.networking.k8s.io.v1.HTTPRouteSpecRulesBackendRefsFiltersUrlRewrite" = {

      options = {
        "hostname" = mkOption {
          description = "Hostname is the value to be used to replace the Host header value during\nforwarding.\n\nSupport: Extended";
          type = types.nullOr types.str;
        };
        "path" = mkOption {
          description = "Path defines a path rewrite.\n\nSupport: Extended";
          type = types.nullOr (
            submoduleOf "gateway.networking.k8s.io.v1.HTTPRouteSpecRulesBackendRefsFiltersUrlRewritePath"
          );
        };
      };

      config = {
        "hostname" = mkOverride 1002 null;
        "path" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1.HTTPRouteSpecRulesBackendRefsFiltersUrlRewritePath" = {

      options = {
        "replaceFullPath" = mkOption {
          description = "ReplaceFullPath specifies the value with which to replace the full path\nof a request during a rewrite or redirect.";
          type = types.nullOr types.str;
        };
        "replacePrefixMatch" = mkOption {
          description = "ReplacePrefixMatch specifies the value with which to replace the prefix\nmatch of a request during a rewrite or redirect. For example, a request\nto \"/foo/bar\" with a prefix match of \"/foo\" and a ReplacePrefixMatch\nof \"/xyz\" would be modified to \"/xyz/bar\".\n\nNote that this matches the behavior of the PathPrefix match type. This\nmatches full path elements. A path element refers to the list of labels\nin the path split by the `/` separator. When specified, a trailing `/` is\nignored. For example, the paths `/abc`, `/abc/`, and `/abc/def` would all\nmatch the prefix `/abc`, but the path `/abcd` would not.\n\nReplacePrefixMatch is only compatible with a `PathPrefix` HTTPRouteMatch.\nUsing any other HTTPRouteMatch type on the same HTTPRouteRule will result in\nthe implementation setting the Accepted Condition for the Route to `status: False`.\n\nRequest Path | Prefix Match | Replace Prefix | Modified Path";
          type = types.nullOr types.str;
        };
        "type" = mkOption {
          description = "Type defines the type of path modifier. Additional types may be\nadded in a future release of the API.\n\nNote that values may be added to this enum, implementations\nmust ensure that unknown values will not cause a crash.\n\nUnknown values here must result in the implementation setting the\nAccepted Condition for the Route to `status: False`, with a\nReason of `UnsupportedValue`.";
          type = types.str;
        };
      };

      config = {
        "replaceFullPath" = mkOverride 1002 null;
        "replacePrefixMatch" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1.HTTPRouteSpecRulesFilters" = {

      options = {
        "extensionRef" = mkOption {
          description = "ExtensionRef is an optional, implementation-specific extension to the\n\"filter\" behavior.  For example, resource \"myroutefilter\" in group\n\"networking.example.net\"). ExtensionRef MUST NOT be used for core and\nextended filters.\n\nThis filter can be used multiple times within the same rule.\n\nSupport: Implementation-specific";
          type = types.nullOr (
            submoduleOf "gateway.networking.k8s.io.v1.HTTPRouteSpecRulesFiltersExtensionRef"
          );
        };
        "requestHeaderModifier" = mkOption {
          description = "RequestHeaderModifier defines a schema for a filter that modifies request\nheaders.\n\nSupport: Core";
          type = types.nullOr (
            submoduleOf "gateway.networking.k8s.io.v1.HTTPRouteSpecRulesFiltersRequestHeaderModifier"
          );
        };
        "requestMirror" = mkOption {
          description = "RequestMirror defines a schema for a filter that mirrors requests.\nRequests are sent to the specified destination, but responses from\nthat destination are ignored.\n\nThis filter can be used multiple times within the same rule. Note that\nnot all implementations will be able to support mirroring to multiple\nbackends.\n\nSupport: Extended";
          type = types.nullOr (
            submoduleOf "gateway.networking.k8s.io.v1.HTTPRouteSpecRulesFiltersRequestMirror"
          );
        };
        "requestRedirect" = mkOption {
          description = "RequestRedirect defines a schema for a filter that responds to the\nrequest with an HTTP redirection.\n\nSupport: Core";
          type = types.nullOr (
            submoduleOf "gateway.networking.k8s.io.v1.HTTPRouteSpecRulesFiltersRequestRedirect"
          );
        };
        "responseHeaderModifier" = mkOption {
          description = "ResponseHeaderModifier defines a schema for a filter that modifies response\nheaders.\n\nSupport: Extended";
          type = types.nullOr (
            submoduleOf "gateway.networking.k8s.io.v1.HTTPRouteSpecRulesFiltersResponseHeaderModifier"
          );
        };
        "type" = mkOption {
          description = "Type identifies the type of filter to apply. As with other API fields,\ntypes are classified into three conformance levels:\n\n- Core: Filter types and their corresponding configuration defined by\n  \"Support: Core\" in this package, e.g. \"RequestHeaderModifier\". All\n  implementations must support core filters.\n\n- Extended: Filter types and their corresponding configuration defined by\n  \"Support: Extended\" in this package, e.g. \"RequestMirror\". Implementers\n  are encouraged to support extended filters.\n\n- Implementation-specific: Filters that are defined and supported by\n  specific vendors.\n  In the future, filters showing convergence in behavior across multiple\n  implementations will be considered for inclusion in extended or core\n  conformance levels. Filter-specific configuration for such filters\n  is specified using the ExtensionRef field. `Type` should be set to\n  \"ExtensionRef\" for custom filters.\n\nImplementers are encouraged to define custom implementation types to\nextend the core API with implementation-specific behavior.\n\nIf a reference to a custom filter type cannot be resolved, the filter\nMUST NOT be skipped. Instead, requests that would have been processed by\nthat filter MUST receive a HTTP error response.\n\nNote that values may be added to this enum, implementations\nmust ensure that unknown values will not cause a crash.\n\nUnknown values here must result in the implementation setting the\nAccepted Condition for the Route to `status: False`, with a\nReason of `UnsupportedValue`.";
          type = types.str;
        };
        "urlRewrite" = mkOption {
          description = "URLRewrite defines a schema for a filter that modifies a request during forwarding.\n\nSupport: Extended";
          type = types.nullOr (
            submoduleOf "gateway.networking.k8s.io.v1.HTTPRouteSpecRulesFiltersUrlRewrite"
          );
        };
      };

      config = {
        "extensionRef" = mkOverride 1002 null;
        "requestHeaderModifier" = mkOverride 1002 null;
        "requestMirror" = mkOverride 1002 null;
        "requestRedirect" = mkOverride 1002 null;
        "responseHeaderModifier" = mkOverride 1002 null;
        "urlRewrite" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1.HTTPRouteSpecRulesFiltersExtensionRef" = {

      options = {
        "group" = mkOption {
          description = "Group is the group of the referent. For example, \"gateway.networking.k8s.io\".\nWhen unspecified or empty string, core API group is inferred.";
          type = types.str;
        };
        "kind" = mkOption {
          description = "Kind is kind of the referent. For example \"HTTPRoute\" or \"Service\".";
          type = types.str;
        };
        "name" = mkOption {
          description = "Name is the name of the referent.";
          type = types.str;
        };
      };

      config = { };

    };
    "gateway.networking.k8s.io.v1.HTTPRouteSpecRulesFiltersRequestHeaderModifier" = {

      options = {
        "add" = mkOption {
          description = "Add adds the given header(s) (name, value) to the request\nbefore the action. It appends to any existing values associated\nwith the header name.\n\nInput:\n  GET /foo HTTP/1.1\n  my-header: foo\n\nConfig:\n  add:\n  - name: \"my-header\"\n    value: \"bar,baz\"\n\nOutput:\n  GET /foo HTTP/1.1\n  my-header: foo,bar,baz";
          type = types.nullOr (
            coerceAttrsOfSubmodulesToListByKey
              "gateway.networking.k8s.io.v1.HTTPRouteSpecRulesFiltersRequestHeaderModifierAdd"
              "name"
              [ "name" ]
          );
          apply = attrsToList;
        };
        "remove" = mkOption {
          description = "Remove the given header(s) from the HTTP request before the action. The\nvalue of Remove is a list of HTTP header names. Note that the header\nnames are case-insensitive (see\nhttps://datatracker.ietf.org/doc/html/rfc2616#section-4.2).\n\nInput:\n  GET /foo HTTP/1.1\n  my-header1: foo\n  my-header2: bar\n  my-header3: baz\n\nConfig:\n  remove: [\"my-header1\", \"my-header3\"]\n\nOutput:\n  GET /foo HTTP/1.1\n  my-header2: bar";
          type = types.nullOr (types.listOf types.str);
        };
        "set" = mkOption {
          description = "Set overwrites the request with the given header (name, value)\nbefore the action.\n\nInput:\n  GET /foo HTTP/1.1\n  my-header: foo\n\nConfig:\n  set:\n  - name: \"my-header\"\n    value: \"bar\"\n\nOutput:\n  GET /foo HTTP/1.1\n  my-header: bar";
          type = types.nullOr (
            coerceAttrsOfSubmodulesToListByKey
              "gateway.networking.k8s.io.v1.HTTPRouteSpecRulesFiltersRequestHeaderModifierSet"
              "name"
              [ "name" ]
          );
          apply = attrsToList;
        };
      };

      config = {
        "add" = mkOverride 1002 null;
        "remove" = mkOverride 1002 null;
        "set" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1.HTTPRouteSpecRulesFiltersRequestHeaderModifierAdd" = {

      options = {
        "name" = mkOption {
          description = "Name is the name of the HTTP Header to be matched. Name matching MUST be\ncase-insensitive. (See https://tools.ietf.org/html/rfc7230#section-3.2).\n\nIf multiple entries specify equivalent header names, the first entry with\nan equivalent name MUST be considered for a match. Subsequent entries\nwith an equivalent header name MUST be ignored. Due to the\ncase-insensitivity of header names, \"foo\" and \"Foo\" are considered\nequivalent.";
          type = types.str;
        };
        "value" = mkOption {
          description = "Value is the value of HTTP Header to be matched.";
          type = types.str;
        };
      };

      config = { };

    };
    "gateway.networking.k8s.io.v1.HTTPRouteSpecRulesFiltersRequestHeaderModifierSet" = {

      options = {
        "name" = mkOption {
          description = "Name is the name of the HTTP Header to be matched. Name matching MUST be\ncase-insensitive. (See https://tools.ietf.org/html/rfc7230#section-3.2).\n\nIf multiple entries specify equivalent header names, the first entry with\nan equivalent name MUST be considered for a match. Subsequent entries\nwith an equivalent header name MUST be ignored. Due to the\ncase-insensitivity of header names, \"foo\" and \"Foo\" are considered\nequivalent.";
          type = types.str;
        };
        "value" = mkOption {
          description = "Value is the value of HTTP Header to be matched.";
          type = types.str;
        };
      };

      config = { };

    };
    "gateway.networking.k8s.io.v1.HTTPRouteSpecRulesFiltersRequestMirror" = {

      options = {
        "backendRef" = mkOption {
          description = "BackendRef references a resource where mirrored requests are sent.\n\nMirrored requests must be sent only to a single destination endpoint\nwithin this BackendRef, irrespective of how many endpoints are present\nwithin this BackendRef.\n\nIf the referent cannot be found, this BackendRef is invalid and must be\ndropped from the Gateway. The controller must ensure the \"ResolvedRefs\"\ncondition on the Route status is set to `status: False` and not configure\nthis backend in the underlying implementation.\n\nIf there is a cross-namespace reference to an *existing* object\nthat is not allowed by a ReferenceGrant, the controller must ensure the\n\"ResolvedRefs\"  condition on the Route is set to `status: False`,\nwith the \"RefNotPermitted\" reason and not configure this backend in the\nunderlying implementation.\n\nIn either error case, the Message of the `ResolvedRefs` Condition\nshould be used to provide more detail about the problem.\n\nSupport: Extended for Kubernetes Service\n\nSupport: Implementation-specific for any other resource";
          type = submoduleOf "gateway.networking.k8s.io.v1.HTTPRouteSpecRulesFiltersRequestMirrorBackendRef";
        };
        "fraction" = mkOption {
          description = "Fraction represents the fraction of requests that should be\nmirrored to BackendRef.\n\nOnly one of Fraction or Percent may be specified. If neither field\nis specified, 100% of requests will be mirrored.";
          type = types.nullOr (
            submoduleOf "gateway.networking.k8s.io.v1.HTTPRouteSpecRulesFiltersRequestMirrorFraction"
          );
        };
        "percent" = mkOption {
          description = "Percent represents the percentage of requests that should be\nmirrored to BackendRef. Its minimum value is 0 (indicating 0% of\nrequests) and its maximum value is 100 (indicating 100% of requests).\n\nOnly one of Fraction or Percent may be specified. If neither field\nis specified, 100% of requests will be mirrored.";
          type = types.nullOr types.int;
        };
      };

      config = {
        "fraction" = mkOverride 1002 null;
        "percent" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1.HTTPRouteSpecRulesFiltersRequestMirrorBackendRef" = {

      options = {
        "group" = mkOption {
          description = "Group is the group of the referent. For example, \"gateway.networking.k8s.io\".\nWhen unspecified or empty string, core API group is inferred.";
          type = types.nullOr types.str;
        };
        "kind" = mkOption {
          description = "Kind is the Kubernetes resource kind of the referent. For example\n\"Service\".\n\nDefaults to \"Service\" when not specified.\n\nExternalName services can refer to CNAME DNS records that may live\noutside of the cluster and as such are difficult to reason about in\nterms of conformance. They also may not be safe to forward to (see\nCVE-2021-25740 for more information). Implementations SHOULD NOT\nsupport ExternalName Services.\n\nSupport: Core (Services with a type other than ExternalName)\n\nSupport: Implementation-specific (Services with type ExternalName)";
          type = types.nullOr types.str;
        };
        "name" = mkOption {
          description = "Name is the name of the referent.";
          type = types.str;
        };
        "namespace" = mkOption {
          description = "Namespace is the namespace of the backend. When unspecified, the local\nnamespace is inferred.\n\nNote that when a namespace different than the local namespace is specified,\na ReferenceGrant object is required in the referent namespace to allow that\nnamespace's owner to accept the reference. See the ReferenceGrant\ndocumentation for details.\n\nSupport: Core";
          type = types.nullOr types.str;
        };
        "port" = mkOption {
          description = "Port specifies the destination port number to use for this resource.\nPort is required when the referent is a Kubernetes Service. In this\ncase, the port number is the service port number, not the target port.\nFor other resources, destination port might be derived from the referent\nresource or this field.";
          type = types.nullOr types.int;
        };
      };

      config = {
        "group" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
        "port" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1.HTTPRouteSpecRulesFiltersRequestMirrorFraction" = {

      options = {
        "denominator" = mkOption {
          description = "";
          type = types.nullOr types.int;
        };
        "numerator" = mkOption {
          description = "";
          type = types.int;
        };
      };

      config = {
        "denominator" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1.HTTPRouteSpecRulesFiltersRequestRedirect" = {

      options = {
        "hostname" = mkOption {
          description = "Hostname is the hostname to be used in the value of the `Location`\nheader in the response.\nWhen empty, the hostname in the `Host` header of the request is used.\n\nSupport: Core";
          type = types.nullOr types.str;
        };
        "path" = mkOption {
          description = "Path defines parameters used to modify the path of the incoming request.\nThe modified path is then used to construct the `Location` header. When\nempty, the request path is used as-is.\n\nSupport: Extended";
          type = types.nullOr (
            submoduleOf "gateway.networking.k8s.io.v1.HTTPRouteSpecRulesFiltersRequestRedirectPath"
          );
        };
        "port" = mkOption {
          description = "Port is the port to be used in the value of the `Location`\nheader in the response.\n\nIf no port is specified, the redirect port MUST be derived using the\nfollowing rules:\n\n* If redirect scheme is not-empty, the redirect port MUST be the well-known\n  port associated with the redirect scheme. Specifically \"http\" to port 80\n  and \"https\" to port 443. If the redirect scheme does not have a\n  well-known port, the listener port of the Gateway SHOULD be used.\n* If redirect scheme is empty, the redirect port MUST be the Gateway\n  Listener port.\n\nImplementations SHOULD NOT add the port number in the 'Location'\nheader in the following cases:\n\n* A Location header that will use HTTP (whether that is determined via\n  the Listener protocol or the Scheme field) _and_ use port 80.\n* A Location header that will use HTTPS (whether that is determined via\n  the Listener protocol or the Scheme field) _and_ use port 443.\n\nSupport: Extended";
          type = types.nullOr types.int;
        };
        "scheme" = mkOption {
          description = "Scheme is the scheme to be used in the value of the `Location` header in\nthe response. When empty, the scheme of the request is used.\n\nScheme redirects can affect the port of the redirect, for more information,\nrefer to the documentation for the port field of this filter.\n\nNote that values may be added to this enum, implementations\nmust ensure that unknown values will not cause a crash.\n\nUnknown values here must result in the implementation setting the\nAccepted Condition for the Route to `status: False`, with a\nReason of `UnsupportedValue`.\n\nSupport: Extended";
          type = types.nullOr types.str;
        };
        "statusCode" = mkOption {
          description = "StatusCode is the HTTP status code to be used in response.\n\nNote that values may be added to this enum, implementations\nmust ensure that unknown values will not cause a crash.\n\nUnknown values here must result in the implementation setting the\nAccepted Condition for the Route to `status: False`, with a\nReason of `UnsupportedValue`.\n\nSupport: Core";
          type = types.nullOr types.int;
        };
      };

      config = {
        "hostname" = mkOverride 1002 null;
        "path" = mkOverride 1002 null;
        "port" = mkOverride 1002 null;
        "scheme" = mkOverride 1002 null;
        "statusCode" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1.HTTPRouteSpecRulesFiltersRequestRedirectPath" = {

      options = {
        "replaceFullPath" = mkOption {
          description = "ReplaceFullPath specifies the value with which to replace the full path\nof a request during a rewrite or redirect.";
          type = types.nullOr types.str;
        };
        "replacePrefixMatch" = mkOption {
          description = "ReplacePrefixMatch specifies the value with which to replace the prefix\nmatch of a request during a rewrite or redirect. For example, a request\nto \"/foo/bar\" with a prefix match of \"/foo\" and a ReplacePrefixMatch\nof \"/xyz\" would be modified to \"/xyz/bar\".\n\nNote that this matches the behavior of the PathPrefix match type. This\nmatches full path elements. A path element refers to the list of labels\nin the path split by the `/` separator. When specified, a trailing `/` is\nignored. For example, the paths `/abc`, `/abc/`, and `/abc/def` would all\nmatch the prefix `/abc`, but the path `/abcd` would not.\n\nReplacePrefixMatch is only compatible with a `PathPrefix` HTTPRouteMatch.\nUsing any other HTTPRouteMatch type on the same HTTPRouteRule will result in\nthe implementation setting the Accepted Condition for the Route to `status: False`.\n\nRequest Path | Prefix Match | Replace Prefix | Modified Path";
          type = types.nullOr types.str;
        };
        "type" = mkOption {
          description = "Type defines the type of path modifier. Additional types may be\nadded in a future release of the API.\n\nNote that values may be added to this enum, implementations\nmust ensure that unknown values will not cause a crash.\n\nUnknown values here must result in the implementation setting the\nAccepted Condition for the Route to `status: False`, with a\nReason of `UnsupportedValue`.";
          type = types.str;
        };
      };

      config = {
        "replaceFullPath" = mkOverride 1002 null;
        "replacePrefixMatch" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1.HTTPRouteSpecRulesFiltersResponseHeaderModifier" = {

      options = {
        "add" = mkOption {
          description = "Add adds the given header(s) (name, value) to the request\nbefore the action. It appends to any existing values associated\nwith the header name.\n\nInput:\n  GET /foo HTTP/1.1\n  my-header: foo\n\nConfig:\n  add:\n  - name: \"my-header\"\n    value: \"bar,baz\"\n\nOutput:\n  GET /foo HTTP/1.1\n  my-header: foo,bar,baz";
          type = types.nullOr (
            coerceAttrsOfSubmodulesToListByKey
              "gateway.networking.k8s.io.v1.HTTPRouteSpecRulesFiltersResponseHeaderModifierAdd"
              "name"
              [ "name" ]
          );
          apply = attrsToList;
        };
        "remove" = mkOption {
          description = "Remove the given header(s) from the HTTP request before the action. The\nvalue of Remove is a list of HTTP header names. Note that the header\nnames are case-insensitive (see\nhttps://datatracker.ietf.org/doc/html/rfc2616#section-4.2).\n\nInput:\n  GET /foo HTTP/1.1\n  my-header1: foo\n  my-header2: bar\n  my-header3: baz\n\nConfig:\n  remove: [\"my-header1\", \"my-header3\"]\n\nOutput:\n  GET /foo HTTP/1.1\n  my-header2: bar";
          type = types.nullOr (types.listOf types.str);
        };
        "set" = mkOption {
          description = "Set overwrites the request with the given header (name, value)\nbefore the action.\n\nInput:\n  GET /foo HTTP/1.1\n  my-header: foo\n\nConfig:\n  set:\n  - name: \"my-header\"\n    value: \"bar\"\n\nOutput:\n  GET /foo HTTP/1.1\n  my-header: bar";
          type = types.nullOr (
            coerceAttrsOfSubmodulesToListByKey
              "gateway.networking.k8s.io.v1.HTTPRouteSpecRulesFiltersResponseHeaderModifierSet"
              "name"
              [ "name" ]
          );
          apply = attrsToList;
        };
      };

      config = {
        "add" = mkOverride 1002 null;
        "remove" = mkOverride 1002 null;
        "set" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1.HTTPRouteSpecRulesFiltersResponseHeaderModifierAdd" = {

      options = {
        "name" = mkOption {
          description = "Name is the name of the HTTP Header to be matched. Name matching MUST be\ncase-insensitive. (See https://tools.ietf.org/html/rfc7230#section-3.2).\n\nIf multiple entries specify equivalent header names, the first entry with\nan equivalent name MUST be considered for a match. Subsequent entries\nwith an equivalent header name MUST be ignored. Due to the\ncase-insensitivity of header names, \"foo\" and \"Foo\" are considered\nequivalent.";
          type = types.str;
        };
        "value" = mkOption {
          description = "Value is the value of HTTP Header to be matched.";
          type = types.str;
        };
      };

      config = { };

    };
    "gateway.networking.k8s.io.v1.HTTPRouteSpecRulesFiltersResponseHeaderModifierSet" = {

      options = {
        "name" = mkOption {
          description = "Name is the name of the HTTP Header to be matched. Name matching MUST be\ncase-insensitive. (See https://tools.ietf.org/html/rfc7230#section-3.2).\n\nIf multiple entries specify equivalent header names, the first entry with\nan equivalent name MUST be considered for a match. Subsequent entries\nwith an equivalent header name MUST be ignored. Due to the\ncase-insensitivity of header names, \"foo\" and \"Foo\" are considered\nequivalent.";
          type = types.str;
        };
        "value" = mkOption {
          description = "Value is the value of HTTP Header to be matched.";
          type = types.str;
        };
      };

      config = { };

    };
    "gateway.networking.k8s.io.v1.HTTPRouteSpecRulesFiltersUrlRewrite" = {

      options = {
        "hostname" = mkOption {
          description = "Hostname is the value to be used to replace the Host header value during\nforwarding.\n\nSupport: Extended";
          type = types.nullOr types.str;
        };
        "path" = mkOption {
          description = "Path defines a path rewrite.\n\nSupport: Extended";
          type = types.nullOr (
            submoduleOf "gateway.networking.k8s.io.v1.HTTPRouteSpecRulesFiltersUrlRewritePath"
          );
        };
      };

      config = {
        "hostname" = mkOverride 1002 null;
        "path" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1.HTTPRouteSpecRulesFiltersUrlRewritePath" = {

      options = {
        "replaceFullPath" = mkOption {
          description = "ReplaceFullPath specifies the value with which to replace the full path\nof a request during a rewrite or redirect.";
          type = types.nullOr types.str;
        };
        "replacePrefixMatch" = mkOption {
          description = "ReplacePrefixMatch specifies the value with which to replace the prefix\nmatch of a request during a rewrite or redirect. For example, a request\nto \"/foo/bar\" with a prefix match of \"/foo\" and a ReplacePrefixMatch\nof \"/xyz\" would be modified to \"/xyz/bar\".\n\nNote that this matches the behavior of the PathPrefix match type. This\nmatches full path elements. A path element refers to the list of labels\nin the path split by the `/` separator. When specified, a trailing `/` is\nignored. For example, the paths `/abc`, `/abc/`, and `/abc/def` would all\nmatch the prefix `/abc`, but the path `/abcd` would not.\n\nReplacePrefixMatch is only compatible with a `PathPrefix` HTTPRouteMatch.\nUsing any other HTTPRouteMatch type on the same HTTPRouteRule will result in\nthe implementation setting the Accepted Condition for the Route to `status: False`.\n\nRequest Path | Prefix Match | Replace Prefix | Modified Path";
          type = types.nullOr types.str;
        };
        "type" = mkOption {
          description = "Type defines the type of path modifier. Additional types may be\nadded in a future release of the API.\n\nNote that values may be added to this enum, implementations\nmust ensure that unknown values will not cause a crash.\n\nUnknown values here must result in the implementation setting the\nAccepted Condition for the Route to `status: False`, with a\nReason of `UnsupportedValue`.";
          type = types.str;
        };
      };

      config = {
        "replaceFullPath" = mkOverride 1002 null;
        "replacePrefixMatch" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1.HTTPRouteSpecRulesMatches" = {

      options = {
        "headers" = mkOption {
          description = "Headers specifies HTTP request header matchers. Multiple match values are\nANDed together, meaning, a request must match all the specified headers\nto select the route.";
          type = types.nullOr (
            coerceAttrsOfSubmodulesToListByKey "gateway.networking.k8s.io.v1.HTTPRouteSpecRulesMatchesHeaders"
              "name"
              [ "name" ]
          );
          apply = attrsToList;
        };
        "method" = mkOption {
          description = "Method specifies HTTP method matcher.\nWhen specified, this route will be matched only if the request has the\nspecified method.\n\nSupport: Extended";
          type = types.nullOr types.str;
        };
        "path" = mkOption {
          description = "Path specifies a HTTP request path matcher. If this field is not\nspecified, a default prefix match on the \"/\" path is provided.";
          type = types.nullOr (submoduleOf "gateway.networking.k8s.io.v1.HTTPRouteSpecRulesMatchesPath");
        };
        "queryParams" = mkOption {
          description = "QueryParams specifies HTTP query parameter matchers. Multiple match\nvalues are ANDed together, meaning, a request must match all the\nspecified query parameters to select the route.\n\nSupport: Extended";
          type = types.nullOr (
            coerceAttrsOfSubmodulesToListByKey
              "gateway.networking.k8s.io.v1.HTTPRouteSpecRulesMatchesQueryParams"
              "name"
              [ "name" ]
          );
          apply = attrsToList;
        };
      };

      config = {
        "headers" = mkOverride 1002 null;
        "method" = mkOverride 1002 null;
        "path" = mkOverride 1002 null;
        "queryParams" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1.HTTPRouteSpecRulesMatchesHeaders" = {

      options = {
        "name" = mkOption {
          description = "Name is the name of the HTTP Header to be matched. Name matching MUST be\ncase-insensitive. (See https://tools.ietf.org/html/rfc7230#section-3.2).\n\nIf multiple entries specify equivalent header names, only the first\nentry with an equivalent name MUST be considered for a match. Subsequent\nentries with an equivalent header name MUST be ignored. Due to the\ncase-insensitivity of header names, \"foo\" and \"Foo\" are considered\nequivalent.\n\nWhen a header is repeated in an HTTP request, it is\nimplementation-specific behavior as to how this is represented.\nGenerally, proxies should follow the guidance from the RFC:\nhttps://www.rfc-editor.org/rfc/rfc7230.html#section-3.2.2 regarding\nprocessing a repeated header, with special handling for \"Set-Cookie\".";
          type = types.str;
        };
        "type" = mkOption {
          description = "Type specifies how to match against the value of the header.\n\nSupport: Core (Exact)\n\nSupport: Implementation-specific (RegularExpression)\n\nSince RegularExpression HeaderMatchType has implementation-specific\nconformance, implementations can support POSIX, PCRE or any other dialects\nof regular expressions. Please read the implementation's documentation to\ndetermine the supported dialect.";
          type = types.nullOr types.str;
        };
        "value" = mkOption {
          description = "Value is the value of HTTP Header to be matched.";
          type = types.str;
        };
      };

      config = {
        "type" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1.HTTPRouteSpecRulesMatchesPath" = {

      options = {
        "type" = mkOption {
          description = "Type specifies how to match against the path Value.\n\nSupport: Core (Exact, PathPrefix)\n\nSupport: Implementation-specific (RegularExpression)";
          type = types.nullOr types.str;
        };
        "value" = mkOption {
          description = "Value of the HTTP path to match against.";
          type = types.nullOr types.str;
        };
      };

      config = {
        "type" = mkOverride 1002 null;
        "value" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1.HTTPRouteSpecRulesMatchesQueryParams" = {

      options = {
        "name" = mkOption {
          description = "Name is the name of the HTTP query param to be matched. This must be an\nexact string match. (See\nhttps://tools.ietf.org/html/rfc7230#section-2.7.3).\n\nIf multiple entries specify equivalent query param names, only the first\nentry with an equivalent name MUST be considered for a match. Subsequent\nentries with an equivalent query param name MUST be ignored.\n\nIf a query param is repeated in an HTTP request, the behavior is\npurposely left undefined, since different data planes have different\ncapabilities. However, it is *recommended* that implementations should\nmatch against the first value of the param if the data plane supports it,\nas this behavior is expected in other load balancing contexts outside of\nthe Gateway API.\n\nUsers SHOULD NOT route traffic based on repeated query params to guard\nthemselves against potential differences in the implementations.";
          type = types.str;
        };
        "type" = mkOption {
          description = "Type specifies how to match against the value of the query parameter.\n\nSupport: Extended (Exact)\n\nSupport: Implementation-specific (RegularExpression)\n\nSince RegularExpression QueryParamMatchType has Implementation-specific\nconformance, implementations can support POSIX, PCRE or any other\ndialects of regular expressions. Please read the implementation's\ndocumentation to determine the supported dialect.";
          type = types.nullOr types.str;
        };
        "value" = mkOption {
          description = "Value is the value of HTTP query param to be matched.";
          type = types.str;
        };
      };

      config = {
        "type" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1.HTTPRouteSpecRulesTimeouts" = {

      options = {
        "backendRequest" = mkOption {
          description = "BackendRequest specifies a timeout for an individual request from the gateway\nto a backend. This covers the time from when the request first starts being\nsent from the gateway to when the full response has been received from the backend.\n\nSetting a timeout to the zero duration (e.g. \"0s\") SHOULD disable the timeout\ncompletely. Implementations that cannot completely disable the timeout MUST\ninstead interpret the zero duration as the longest possible value to which\nthe timeout can be set.\n\nAn entire client HTTP transaction with a gateway, covered by the Request timeout,\nmay result in more than one call from the gateway to the destination backend,\nfor example, if automatic retries are supported.\n\nThe value of BackendRequest must be a Gateway API Duration string as defined by\nGEP-2257.  When this field is unspecified, its behavior is implementation-specific;\nwhen specified, the value of BackendRequest must be no more than the value of the\nRequest timeout (since the Request timeout encompasses the BackendRequest timeout).\n\nSupport: Extended";
          type = types.nullOr types.str;
        };
        "request" = mkOption {
          description = "Request specifies the maximum duration for a gateway to respond to an HTTP request.\nIf the gateway has not been able to respond before this deadline is met, the gateway\nMUST return a timeout error.\n\nFor example, setting the `rules.timeouts.request` field to the value `10s` in an\n`HTTPRoute` will cause a timeout if a client request is taking longer than 10 seconds\nto complete.\n\nSetting a timeout to the zero duration (e.g. \"0s\") SHOULD disable the timeout\ncompletely. Implementations that cannot completely disable the timeout MUST\ninstead interpret the zero duration as the longest possible value to which\nthe timeout can be set.\n\nThis timeout is intended to cover as close to the whole request-response transaction\nas possible although an implementation MAY choose to start the timeout after the entire\nrequest stream has been received instead of immediately after the transaction is\ninitiated by the client.\n\nThe value of Request is a Gateway API Duration string as defined by GEP-2257. When this\nfield is unspecified, request timeout behavior is implementation-specific.\n\nSupport: Extended";
          type = types.nullOr types.str;
        };
      };

      config = {
        "backendRequest" = mkOverride 1002 null;
        "request" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1.HTTPRouteStatus" = {

      options = {
        "parents" = mkOption {
          description = "Parents is a list of parent resources (usually Gateways) that are\nassociated with the route, and the status of the route with respect to\neach parent. When this route attaches to a parent, the controller that\nmanages the parent must add an entry to this list when the controller\nfirst sees the route and should update the entry as appropriate when the\nroute or gateway is modified.\n\nNote that parent references that cannot be resolved by an implementation\nof this API will not be added to this list. Implementations of this API\ncan only populate Route status for the Gateways/parent resources they are\nresponsible for.\n\nA maximum of 32 Gateways will be represented in this list. An empty list\nmeans the route has not been attached to any Gateway.";
          type = types.listOf (submoduleOf "gateway.networking.k8s.io.v1.HTTPRouteStatusParents");
        };
      };

      config = { };

    };
    "gateway.networking.k8s.io.v1.HTTPRouteStatusParents" = {

      options = {
        "conditions" = mkOption {
          description = "Conditions describes the status of the route with respect to the Gateway.\nNote that the route's availability is also subject to the Gateway's own\nstatus conditions and listener status.\n\nIf the Route's ParentRef specifies an existing Gateway that supports\nRoutes of this kind AND that Gateway's controller has sufficient access,\nthen that Gateway's controller MUST set the \"Accepted\" condition on the\nRoute, to indicate whether the route has been accepted or rejected by the\nGateway, and why.\n\nA Route MUST be considered \"Accepted\" if at least one of the Route's\nrules is implemented by the Gateway.\n\nThere are a number of cases where the \"Accepted\" condition may not be set\ndue to lack of controller visibility, that includes when:\n\n* The Route refers to a nonexistent parent.\n* The Route is of a type that the controller does not support.\n* The Route is in a namespace the controller does not have access to.";
          type = types.listOf (submoduleOf "gateway.networking.k8s.io.v1.HTTPRouteStatusParentsConditions");
        };
        "controllerName" = mkOption {
          description = "ControllerName is a domain/path string that indicates the name of the\ncontroller that wrote this status. This corresponds with the\ncontrollerName field on GatewayClass.\n\nExample: \"example.net/gateway-controller\".\n\nThe format of this field is DOMAIN \"/\" PATH, where DOMAIN and PATH are\nvalid Kubernetes names\n(https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names).\n\nControllers MUST populate this field when writing status. Controllers should ensure that\nentries to status populated with their ControllerName are cleaned up when they are no\nlonger necessary.";
          type = types.str;
        };
        "parentRef" = mkOption {
          description = "ParentRef corresponds with a ParentRef in the spec that this\nRouteParentStatus struct describes the status of.";
          type = submoduleOf "gateway.networking.k8s.io.v1.HTTPRouteStatusParentsParentRef";
        };
      };

      config = { };

    };
    "gateway.networking.k8s.io.v1.HTTPRouteStatusParentsConditions" = {

      options = {
        "lastTransitionTime" = mkOption {
          description = "lastTransitionTime is the last time the condition transitioned from one status to another.\nThis should be when the underlying condition changed.  If that is not known, then using the time when the API field changed is acceptable.";
          type = types.str;
        };
        "message" = mkOption {
          description = "message is a human readable message indicating details about the transition.\nThis may be an empty string.";
          type = types.str;
        };
        "observedGeneration" = mkOption {
          description = "observedGeneration represents the .metadata.generation that the condition was set based upon.\nFor instance, if .metadata.generation is currently 12, but the .status.conditions[x].observedGeneration is 9, the condition is out of date\nwith respect to the current state of the instance.";
          type = types.nullOr types.int;
        };
        "reason" = mkOption {
          description = "reason contains a programmatic identifier indicating the reason for the condition's last transition.\nProducers of specific condition types may define expected values and meanings for this field,\nand whether the values are considered a guaranteed API.\nThe value should be a CamelCase string.\nThis field may not be empty.";
          type = types.str;
        };
        "status" = mkOption {
          description = "status of the condition, one of True, False, Unknown.";
          type = types.str;
        };
        "type" = mkOption {
          description = "type of condition in CamelCase or in foo.example.com/CamelCase.";
          type = types.str;
        };
      };

      config = {
        "observedGeneration" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1.HTTPRouteStatusParentsParentRef" = {

      options = {
        "group" = mkOption {
          description = "Group is the group of the referent.\nWhen unspecified, \"gateway.networking.k8s.io\" is inferred.\nTo set the core API group (such as for a \"Service\" kind referent),\nGroup must be explicitly set to \"\" (empty string).\n\nSupport: Core";
          type = types.nullOr types.str;
        };
        "kind" = mkOption {
          description = "Kind is kind of the referent.\n\nThere are two kinds of parent resources with \"Core\" support:\n\n* Gateway (Gateway conformance profile)\n* Service (Mesh conformance profile, ClusterIP Services only)\n\nSupport for other resources is Implementation-Specific.";
          type = types.nullOr types.str;
        };
        "name" = mkOption {
          description = "Name is the name of the referent.\n\nSupport: Core";
          type = types.str;
        };
        "namespace" = mkOption {
          description = "Namespace is the namespace of the referent. When unspecified, this refers\nto the local namespace of the Route.\n\nNote that there are specific rules for ParentRefs which cross namespace\nboundaries. Cross-namespace references are only valid if they are explicitly\nallowed by something in the namespace they are referring to. For example:\nGateway has the AllowedRoutes field, and ReferenceGrant provides a\ngeneric way to enable any other kind of cross-namespace reference.\n\nSupport: Core";
          type = types.nullOr types.str;
        };
        "port" = mkOption {
          description = "Port is the network port this Route targets. It can be interpreted\ndifferently based on the type of parent resource.\n\nWhen the parent resource is a Gateway, this targets all listeners\nlistening on the specified port that also support this kind of Route(and\nselect this Route). It's not recommended to set `Port` unless the\nnetworking behaviors specified in a Route must apply to a specific port\nas opposed to a listener(s) whose port(s) may be changed. When both Port\nand SectionName are specified, the name and port of the selected listener\nmust match both specified values.\n\nImplementations MAY choose to support other parent resources.\nImplementations supporting other types of parent resources MUST clearly\ndocument how/if Port is interpreted.\n\nFor the purpose of status, an attachment is considered successful as\nlong as the parent resource accepts it partially. For example, Gateway\nlisteners can restrict which Routes can attach to them by Route kind,\nnamespace, or hostname. If 1 of 2 Gateway listeners accept attachment\nfrom the referencing Route, the Route MUST be considered successfully\nattached. If no Gateway listeners accept attachment from this Route,\nthe Route MUST be considered detached from the Gateway.\n\nSupport: Extended";
          type = types.nullOr types.int;
        };
        "sectionName" = mkOption {
          description = "SectionName is the name of a section within the target resource. In the\nfollowing resources, SectionName is interpreted as the following:\n\n* Gateway: Listener name. When both Port (experimental) and SectionName\nare specified, the name and port of the selected listener must match\nboth specified values.\n* Service: Port name. When both Port (experimental) and SectionName\nare specified, the name and port of the selected listener must match\nboth specified values.\n\nImplementations MAY choose to support attaching Routes to other resources.\nIf that is the case, they MUST clearly document how SectionName is\ninterpreted.\n\nWhen unspecified (empty string), this will reference the entire resource.\nFor the purpose of status, an attachment is considered successful if at\nleast one section in the parent resource accepts it. For example, Gateway\nlisteners can restrict which Routes can attach to them by Route kind,\nnamespace, or hostname. If 1 of 2 Gateway listeners accept attachment from\nthe referencing Route, the Route MUST be considered successfully\nattached. If no Gateway listeners accept attachment from this Route, the\nRoute MUST be considered detached from the Gateway.\n\nSupport: Core";
          type = types.nullOr types.str;
        };
      };

      config = {
        "group" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
        "port" = mkOverride 1002 null;
        "sectionName" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1beta1.Gateway" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object.\nServers should convert recognized schemas to the latest internal value, and\nmay reject unrecognized values.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = types.nullOr types.str;
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents.\nServers may infer this from the endpoint the client submits requests to.\nCannot be updated.\nIn CamelCase.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = types.nullOr types.str;
        };
        "metadata" = mkOption {
          description = "Standard object's metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = types.nullOr (globalSubmoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta");
        };
        "spec" = mkOption {
          description = "Spec defines the desired state of Gateway.";
          type = submoduleOf "gateway.networking.k8s.io.v1beta1.GatewaySpec";
        };
        "status" = mkOption {
          description = "Status defines the current state of Gateway.";
          type = types.nullOr (submoduleOf "gateway.networking.k8s.io.v1beta1.GatewayStatus");
        };
      };

      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1beta1.GatewayClass" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object.\nServers should convert recognized schemas to the latest internal value, and\nmay reject unrecognized values.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = types.nullOr types.str;
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents.\nServers may infer this from the endpoint the client submits requests to.\nCannot be updated.\nIn CamelCase.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = types.nullOr types.str;
        };
        "metadata" = mkOption {
          description = "Standard object's metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = types.nullOr (globalSubmoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta");
        };
        "spec" = mkOption {
          description = "Spec defines the desired state of GatewayClass.";
          type = submoduleOf "gateway.networking.k8s.io.v1beta1.GatewayClassSpec";
        };
        "status" = mkOption {
          description = "Status defines the current state of GatewayClass.\n\nImplementations MUST populate status on all GatewayClass resources which\nspecify their controller name.";
          type = types.nullOr (submoduleOf "gateway.networking.k8s.io.v1beta1.GatewayClassStatus");
        };
      };

      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1beta1.GatewayClassSpec" = {

      options = {
        "controllerName" = mkOption {
          description = "ControllerName is the name of the controller that is managing Gateways of\nthis class. The value of this field MUST be a domain prefixed path.\n\nExample: \"example.net/gateway-controller\".\n\nThis field is not mutable and cannot be empty.\n\nSupport: Core";
          type = types.str;
        };
        "description" = mkOption {
          description = "Description helps describe a GatewayClass with more details.";
          type = types.nullOr types.str;
        };
        "parametersRef" = mkOption {
          description = "ParametersRef is a reference to a resource that contains the configuration\nparameters corresponding to the GatewayClass. This is optional if the\ncontroller does not require any additional configuration.\n\nParametersRef can reference a standard Kubernetes resource, i.e. ConfigMap,\nor an implementation-specific custom resource. The resource can be\ncluster-scoped or namespace-scoped.\n\nIf the referent cannot be found, refers to an unsupported kind, or when\nthe data within that resource is malformed, the GatewayClass SHOULD be\nrejected with the \"Accepted\" status condition set to \"False\" and an\n\"InvalidParameters\" reason.\n\nA Gateway for this GatewayClass may provide its own `parametersRef`. When both are specified,\nthe merging behavior is implementation specific.\nIt is generally recommended that GatewayClass provides defaults that can be overridden by a Gateway.\n\nSupport: Implementation-specific";
          type = types.nullOr (submoduleOf "gateway.networking.k8s.io.v1beta1.GatewayClassSpecParametersRef");
        };
      };

      config = {
        "description" = mkOverride 1002 null;
        "parametersRef" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1beta1.GatewayClassSpecParametersRef" = {

      options = {
        "group" = mkOption {
          description = "Group is the group of the referent.";
          type = types.str;
        };
        "kind" = mkOption {
          description = "Kind is kind of the referent.";
          type = types.str;
        };
        "name" = mkOption {
          description = "Name is the name of the referent.";
          type = types.str;
        };
        "namespace" = mkOption {
          description = "Namespace is the namespace of the referent.\nThis field is required when referring to a Namespace-scoped resource and\nMUST be unset when referring to a Cluster-scoped resource.";
          type = types.nullOr types.str;
        };
      };

      config = {
        "namespace" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1beta1.GatewayClassStatus" = {

      options = {
        "conditions" = mkOption {
          description = "Conditions is the current status from the controller for\nthis GatewayClass.\n\nControllers should prefer to publish conditions using values\nof GatewayClassConditionType for the type of each Condition.";
          type = types.nullOr (
            types.listOf (submoduleOf "gateway.networking.k8s.io.v1beta1.GatewayClassStatusConditions")
          );
        };
        "supportedFeatures" = mkOption {
          description = "SupportedFeatures is the set of features the GatewayClass support.\nIt MUST be sorted in ascending alphabetical order by the Name key.";
          type = types.nullOr (
            coerceAttrsOfSubmodulesToListByKey
              "gateway.networking.k8s.io.v1beta1.GatewayClassStatusSupportedFeatures"
              "name"
              [ "name" ]
          );
          apply = attrsToList;
        };
      };

      config = {
        "conditions" = mkOverride 1002 null;
        "supportedFeatures" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1beta1.GatewayClassStatusConditions" = {

      options = {
        "lastTransitionTime" = mkOption {
          description = "lastTransitionTime is the last time the condition transitioned from one status to another.\nThis should be when the underlying condition changed.  If that is not known, then using the time when the API field changed is acceptable.";
          type = types.str;
        };
        "message" = mkOption {
          description = "message is a human readable message indicating details about the transition.\nThis may be an empty string.";
          type = types.str;
        };
        "observedGeneration" = mkOption {
          description = "observedGeneration represents the .metadata.generation that the condition was set based upon.\nFor instance, if .metadata.generation is currently 12, but the .status.conditions[x].observedGeneration is 9, the condition is out of date\nwith respect to the current state of the instance.";
          type = types.nullOr types.int;
        };
        "reason" = mkOption {
          description = "reason contains a programmatic identifier indicating the reason for the condition's last transition.\nProducers of specific condition types may define expected values and meanings for this field,\nand whether the values are considered a guaranteed API.\nThe value should be a CamelCase string.\nThis field may not be empty.";
          type = types.str;
        };
        "status" = mkOption {
          description = "status of the condition, one of True, False, Unknown.";
          type = types.str;
        };
        "type" = mkOption {
          description = "type of condition in CamelCase or in foo.example.com/CamelCase.";
          type = types.str;
        };
      };

      config = {
        "observedGeneration" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1beta1.GatewayClassStatusSupportedFeatures" = {

      options = {
        "name" = mkOption {
          description = "FeatureName is used to describe distinct features that are covered by\nconformance tests.";
          type = types.str;
        };
      };

      config = { };

    };
    "gateway.networking.k8s.io.v1beta1.GatewaySpec" = {

      options = {
        "addresses" = mkOption {
          description = "Addresses requested for this Gateway. This is optional and behavior can\ndepend on the implementation. If a value is set in the spec and the\nrequested address is invalid or unavailable, the implementation MUST\nindicate this in an associated entry in GatewayStatus.Conditions.\n\nThe Addresses field represents a request for the address(es) on the\n\"outside of the Gateway\", that traffic bound for this Gateway will use.\nThis could be the IP address or hostname of an external load balancer or\nother networking infrastructure, or some other address that traffic will\nbe sent to.\n\nIf no Addresses are specified, the implementation MAY schedule the\nGateway in an implementation-specific manner, assigning an appropriate\nset of Addresses.\n\nThe implementation MUST bind all Listeners to every GatewayAddress that\nit assigns to the Gateway and add a corresponding entry in\nGatewayStatus.Addresses.\n\nSupport: Extended";
          type = types.nullOr (
            types.listOf (submoduleOf "gateway.networking.k8s.io.v1beta1.GatewaySpecAddresses")
          );
        };
        "gatewayClassName" = mkOption {
          description = "GatewayClassName used for this Gateway. This is the name of a\nGatewayClass resource.";
          type = types.str;
        };
        "infrastructure" = mkOption {
          description = "Infrastructure defines infrastructure level attributes about this Gateway instance.\n\nSupport: Extended";
          type = types.nullOr (submoduleOf "gateway.networking.k8s.io.v1beta1.GatewaySpecInfrastructure");
        };
        "listeners" = mkOption {
          description = "Listeners associated with this Gateway. Listeners define\nlogical endpoints that are bound on this Gateway's addresses.\nAt least one Listener MUST be specified.\n\n## Distinct Listeners\n\nEach Listener in a set of Listeners (for example, in a single Gateway)\nMUST be _distinct_, in that a traffic flow MUST be able to be assigned to\nexactly one listener. (This section uses \"set of Listeners\" rather than\n\"Listeners in a single Gateway\" because implementations MAY merge configuration\nfrom multiple Gateways onto a single data plane, and these rules _also_\napply in that case).\n\nPractically, this means that each listener in a set MUST have a unique\ncombination of Port, Protocol, and, if supported by the protocol, Hostname.\n\nSome combinations of port, protocol, and TLS settings are considered\nCore support and MUST be supported by implementations based on the objects\nthey support:\n\nHTTPRoute\n\n1. HTTPRoute, Port: 80, Protocol: HTTP\n2. HTTPRoute, Port: 443, Protocol: HTTPS, TLS Mode: Terminate, TLS keypair provided\n\nTLSRoute\n\n1. TLSRoute, Port: 443, Protocol: TLS, TLS Mode: Passthrough\n\n\"Distinct\" Listeners have the following property:\n\n**The implementation can match inbound requests to a single distinct\nListener**.\n\nWhen multiple Listeners share values for fields (for\nexample, two Listeners with the same Port value), the implementation\ncan match requests to only one of the Listeners using other\nListener fields.\n\nWhen multiple listeners have the same value for the Protocol field, then\neach of the Listeners with matching Protocol values MUST have different\nvalues for other fields.\n\nThe set of fields that MUST be different for a Listener differs per protocol.\nThe following rules define the rules for what fields MUST be considered for\nListeners to be distinct with each protocol currently defined in the\nGateway API spec.\n\nThe set of listeners that all share a protocol value MUST have _different_\nvalues for _at least one_ of these fields to be distinct:\n\n* **HTTP, HTTPS, TLS**: Port, Hostname\n* **TCP, UDP**: Port\n\nOne **very** important rule to call out involves what happens when an\nimplementation:\n\n* Supports TCP protocol Listeners, as well as HTTP, HTTPS, or TLS protocol\n  Listeners, and\n* sees HTTP, HTTPS, or TLS protocols with the same `port` as one with TCP\n  Protocol.\n\nIn this case all the Listeners that share a port with the\nTCP Listener are not distinct and so MUST NOT be accepted.\n\nIf an implementation does not support TCP Protocol Listeners, then the\nprevious rule does not apply, and the TCP Listeners SHOULD NOT be\naccepted.\n\nNote that the `tls` field is not used for determining if a listener is distinct, because\nListeners that _only_ differ on TLS config will still conflict in all cases.\n\n### Listeners that are distinct only by Hostname\n\nWhen the Listeners are distinct based only on Hostname, inbound request\nhostnames MUST match from the most specific to least specific Hostname\nvalues to choose the correct Listener and its associated set of Routes.\n\nExact matches MUST be processed before wildcard matches, and wildcard\nmatches MUST be processed before fallback (empty Hostname value)\nmatches. For example, `\"foo.example.com\"` takes precedence over\n`\"*.example.com\"`, and `\"*.example.com\"` takes precedence over `\"\"`.\n\nAdditionally, if there are multiple wildcard entries, more specific\nwildcard entries must be processed before less specific wildcard entries.\nFor example, `\"*.foo.example.com\"` takes precedence over `\"*.example.com\"`.\n\nThe precise definition here is that the higher the number of dots in the\nhostname to the right of the wildcard character, the higher the precedence.\n\nThe wildcard character will match any number of characters _and dots_ to\nthe left, however, so `\"*.example.com\"` will match both\n`\"foo.bar.example.com\"` _and_ `\"bar.example.com\"`.\n\n## Handling indistinct Listeners\n\nIf a set of Listeners contains Listeners that are not distinct, then those\nListeners are _Conflicted_, and the implementation MUST set the \"Conflicted\"\ncondition in the Listener Status to \"True\".\n\nThe words \"indistinct\" and \"conflicted\" are considered equivalent for the\npurpose of this documentation.\n\nImplementations MAY choose to accept a Gateway with some Conflicted\nListeners only if they only accept the partial Listener set that contains\nno Conflicted Listeners.\n\nSpecifically, an implementation MAY accept a partial Listener set subject to\nthe following rules:\n\n* The implementation MUST NOT pick one conflicting Listener as the winner.\n  ALL indistinct Listeners must not be accepted for processing.\n* At least one distinct Listener MUST be present, or else the Gateway effectively\n  contains _no_ Listeners, and must be rejected from processing as a whole.\n\nThe implementation MUST set a \"ListenersNotValid\" condition on the\nGateway Status when the Gateway contains Conflicted Listeners whether or\nnot they accept the Gateway. That Condition SHOULD clearly\nindicate in the Message which Listeners are conflicted, and which are\nAccepted. Additionally, the Listener status for those listeners SHOULD\nindicate which Listeners are conflicted and not Accepted.\n\n## General Listener behavior\n\nNote that, for all distinct Listeners, requests SHOULD match at most one Listener.\nFor example, if Listeners are defined for \"foo.example.com\" and \"*.example.com\", a\nrequest to \"foo.example.com\" SHOULD only be routed using routes attached\nto the \"foo.example.com\" Listener (and not the \"*.example.com\" Listener).\n\nThis concept is known as \"Listener Isolation\", and it is an Extended feature\nof Gateway API. Implementations that do not support Listener Isolation MUST\nclearly document this, and MUST NOT claim support for the\n`GatewayHTTPListenerIsolation` feature.\n\nImplementations that _do_ support Listener Isolation SHOULD claim support\nfor the Extended `GatewayHTTPListenerIsolation` feature and pass the associated\nconformance tests.\n\n## Compatible Listeners\n\nA Gateway's Listeners are considered _compatible_ if:\n\n1. They are distinct.\n2. The implementation can serve them in compliance with the Addresses\n   requirement that all Listeners are available on all assigned\n   addresses.\n\nCompatible combinations in Extended support are expected to vary across\nimplementations. A combination that is compatible for one implementation\nmay not be compatible for another.\n\nFor example, an implementation that cannot serve both TCP and UDP listeners\non the same address, or cannot mix HTTPS and generic TLS listens on the same port\nwould not consider those cases compatible, even though they are distinct.\n\nImplementations MAY merge separate Gateways onto a single set of\nAddresses if all Listeners across all Gateways are compatible.\n\nIn a future release the MinItems=1 requirement MAY be dropped.\n\nSupport: Core";
          type =
            coerceAttrsOfSubmodulesToListByKey "gateway.networking.k8s.io.v1beta1.GatewaySpecListeners" "name"
              [
                "name"
              ];
          apply = attrsToList;
        };
      };

      config = {
        "addresses" = mkOverride 1002 null;
        "infrastructure" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1beta1.GatewaySpecAddresses" = {

      options = {
        "type" = mkOption {
          description = "Type of the address.";
          type = types.nullOr types.str;
        };
        "value" = mkOption {
          description = "When a value is unspecified, an implementation SHOULD automatically\nassign an address matching the requested type if possible.\n\nIf an implementation does not support an empty value, they MUST set the\n\"Programmed\" condition in status to False with a reason of \"AddressNotAssigned\".\n\nExamples: `1.2.3.4`, `128::1`, `my-ip-address`.";
          type = types.nullOr types.str;
        };
      };

      config = {
        "type" = mkOverride 1002 null;
        "value" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1beta1.GatewaySpecInfrastructure" = {

      options = {
        "annotations" = mkOption {
          description = "Annotations that SHOULD be applied to any resources created in response to this Gateway.\n\nFor implementations creating other Kubernetes objects, this should be the `metadata.annotations` field on resources.\nFor other implementations, this refers to any relevant (implementation specific) \"annotations\" concepts.\n\nAn implementation may chose to add additional implementation-specific annotations as they see fit.\n\nSupport: Extended";
          type = types.nullOr (types.attrsOf types.str);
        };
        "labels" = mkOption {
          description = "Labels that SHOULD be applied to any resources created in response to this Gateway.\n\nFor implementations creating other Kubernetes objects, this should be the `metadata.labels` field on resources.\nFor other implementations, this refers to any relevant (implementation specific) \"labels\" concepts.\n\nAn implementation may chose to add additional implementation-specific labels as they see fit.\n\nIf an implementation maps these labels to Pods, or any other resource that would need to be recreated when labels\nchange, it SHOULD clearly warn about this behavior in documentation.\n\nSupport: Extended";
          type = types.nullOr (types.attrsOf types.str);
        };
        "parametersRef" = mkOption {
          description = "ParametersRef is a reference to a resource that contains the configuration\nparameters corresponding to the Gateway. This is optional if the\ncontroller does not require any additional configuration.\n\nThis follows the same semantics as GatewayClass's `parametersRef`, but on a per-Gateway basis\n\nThe Gateway's GatewayClass may provide its own `parametersRef`. When both are specified,\nthe merging behavior is implementation specific.\nIt is generally recommended that GatewayClass provides defaults that can be overridden by a Gateway.\n\nIf the referent cannot be found, refers to an unsupported kind, or when\nthe data within that resource is malformed, the Gateway SHOULD be\nrejected with the \"Accepted\" status condition set to \"False\" and an\n\"InvalidParameters\" reason.\n\nSupport: Implementation-specific";
          type = types.nullOr (
            submoduleOf "gateway.networking.k8s.io.v1beta1.GatewaySpecInfrastructureParametersRef"
          );
        };
      };

      config = {
        "annotations" = mkOverride 1002 null;
        "labels" = mkOverride 1002 null;
        "parametersRef" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1beta1.GatewaySpecInfrastructureParametersRef" = {

      options = {
        "group" = mkOption {
          description = "Group is the group of the referent.";
          type = types.str;
        };
        "kind" = mkOption {
          description = "Kind is kind of the referent.";
          type = types.str;
        };
        "name" = mkOption {
          description = "Name is the name of the referent.";
          type = types.str;
        };
      };

      config = { };

    };
    "gateway.networking.k8s.io.v1beta1.GatewaySpecListeners" = {

      options = {
        "allowedRoutes" = mkOption {
          description = "AllowedRoutes defines the types of routes that MAY be attached to a\nListener and the trusted namespaces where those Route resources MAY be\npresent.\n\nAlthough a client request may match multiple route rules, only one rule\nmay ultimately receive the request. Matching precedence MUST be\ndetermined in order of the following criteria:\n\n* The most specific match as defined by the Route type.\n* The oldest Route based on creation timestamp. For example, a Route with\n  a creation timestamp of \"2020-09-08 01:02:03\" is given precedence over\n  a Route with a creation timestamp of \"2020-09-08 01:02:04\".\n* If everything else is equivalent, the Route appearing first in\n  alphabetical order (namespace/name) should be given precedence. For\n  example, foo/bar is given precedence over foo/baz.\n\nAll valid rules within a Route attached to this Listener should be\nimplemented. Invalid Route rules can be ignored (sometimes that will mean\nthe full Route). If a Route rule transitions from valid to invalid,\nsupport for that Route rule should be dropped to ensure consistency. For\nexample, even if a filter specified by a Route rule is invalid, the rest\nof the rules within that Route should still be supported.\n\nSupport: Core";
          type = types.nullOr (
            submoduleOf "gateway.networking.k8s.io.v1beta1.GatewaySpecListenersAllowedRoutes"
          );
        };
        "hostname" = mkOption {
          description = "Hostname specifies the virtual hostname to match for protocol types that\ndefine this concept. When unspecified, all hostnames are matched. This\nfield is ignored for protocols that don't require hostname based\nmatching.\n\nImplementations MUST apply Hostname matching appropriately for each of\nthe following protocols:\n\n* TLS: The Listener Hostname MUST match the SNI.\n* HTTP: The Listener Hostname MUST match the Host header of the request.\n* HTTPS: The Listener Hostname SHOULD match both the SNI and Host header.\n  Note that this does not require the SNI and Host header to be the same.\n  The semantics of this are described in more detail below.\n\nTo ensure security, Section 11.1 of RFC-6066 emphasizes that server\nimplementations that rely on SNI hostname matching MUST also verify\nhostnames within the application protocol.\n\nSection 9.1.2 of RFC-7540 provides a mechanism for servers to reject the\nreuse of a connection by responding with the HTTP 421 Misdirected Request\nstatus code. This indicates that the origin server has rejected the\nrequest because it appears to have been misdirected.\n\nTo detect misdirected requests, Gateways SHOULD match the authority of\nthe requests with all the SNI hostname(s) configured across all the\nGateway Listeners on the same port and protocol:\n\n* If another Listener has an exact match or more specific wildcard entry,\n  the Gateway SHOULD return a 421.\n* If the current Listener (selected by SNI matching during ClientHello)\n  does not match the Host:\n    * If another Listener does match the Host the Gateway SHOULD return a\n      421.\n    * If no other Listener matches the Host, the Gateway MUST return a\n      404.\n\nFor HTTPRoute and TLSRoute resources, there is an interaction with the\n`spec.hostnames` array. When both listener and route specify hostnames,\nthere MUST be an intersection between the values for a Route to be\naccepted. For more information, refer to the Route specific Hostnames\ndocumentation.\n\nHostnames that are prefixed with a wildcard label (`*.`) are interpreted\nas a suffix match. That means that a match for `*.example.com` would match\nboth `test.example.com`, and `foo.test.example.com`, but not `example.com`.\n\nSupport: Core";
          type = types.nullOr types.str;
        };
        "name" = mkOption {
          description = "Name is the name of the Listener. This name MUST be unique within a\nGateway.\n\nSupport: Core";
          type = types.str;
        };
        "port" = mkOption {
          description = "Port is the network port. Multiple listeners may use the\nsame port, subject to the Listener compatibility rules.\n\nSupport: Core";
          type = types.int;
        };
        "protocol" = mkOption {
          description = "Protocol specifies the network protocol this listener expects to receive.\n\nSupport: Core";
          type = types.str;
        };
        "tls" = mkOption {
          description = "TLS is the TLS configuration for the Listener. This field is required if\nthe Protocol field is \"HTTPS\" or \"TLS\". It is invalid to set this field\nif the Protocol field is \"HTTP\", \"TCP\", or \"UDP\".\n\nThe association of SNIs to Certificate defined in ListenerTLSConfig is\ndefined based on the Hostname field for this listener.\n\nThe GatewayClass MUST use the longest matching SNI out of all\navailable certificates for any TLS handshake.\n\nSupport: Core";
          type = types.nullOr (submoduleOf "gateway.networking.k8s.io.v1beta1.GatewaySpecListenersTls");
        };
      };

      config = {
        "allowedRoutes" = mkOverride 1002 null;
        "hostname" = mkOverride 1002 null;
        "tls" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1beta1.GatewaySpecListenersAllowedRoutes" = {

      options = {
        "kinds" = mkOption {
          description = "Kinds specifies the groups and kinds of Routes that are allowed to bind\nto this Gateway Listener. When unspecified or empty, the kinds of Routes\nselected are determined using the Listener protocol.\n\nA RouteGroupKind MUST correspond to kinds of Routes that are compatible\nwith the application protocol specified in the Listener's Protocol field.\nIf an implementation does not support or recognize this resource type, it\nMUST set the \"ResolvedRefs\" condition to False for this Listener with the\n\"InvalidRouteKinds\" reason.\n\nSupport: Core";
          type = types.nullOr (
            types.listOf (
              submoduleOf "gateway.networking.k8s.io.v1beta1.GatewaySpecListenersAllowedRoutesKinds"
            )
          );
        };
        "namespaces" = mkOption {
          description = "Namespaces indicates namespaces from which Routes may be attached to this\nListener. This is restricted to the namespace of this Gateway by default.\n\nSupport: Core";
          type = types.nullOr (
            submoduleOf "gateway.networking.k8s.io.v1beta1.GatewaySpecListenersAllowedRoutesNamespaces"
          );
        };
      };

      config = {
        "kinds" = mkOverride 1002 null;
        "namespaces" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1beta1.GatewaySpecListenersAllowedRoutesKinds" = {

      options = {
        "group" = mkOption {
          description = "Group is the group of the Route.";
          type = types.nullOr types.str;
        };
        "kind" = mkOption {
          description = "Kind is the kind of the Route.";
          type = types.str;
        };
      };

      config = {
        "group" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1beta1.GatewaySpecListenersAllowedRoutesNamespaces" = {

      options = {
        "from" = mkOption {
          description = "From indicates where Routes will be selected for this Gateway. Possible\nvalues are:\n\n* All: Routes in all namespaces may be used by this Gateway.\n* Selector: Routes in namespaces selected by the selector may be used by\n  this Gateway.\n* Same: Only Routes in the same namespace may be used by this Gateway.\n\nSupport: Core";
          type = types.nullOr types.str;
        };
        "selector" = mkOption {
          description = "Selector must be specified when From is set to \"Selector\". In that case,\nonly Routes in Namespaces matching this Selector will be selected by this\nGateway. This field is ignored for other values of \"From\".\n\nSupport: Core";
          type = types.nullOr (
            submoduleOf "gateway.networking.k8s.io.v1beta1.GatewaySpecListenersAllowedRoutesNamespacesSelector"
          );
        };
      };

      config = {
        "from" = mkOverride 1002 null;
        "selector" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1beta1.GatewaySpecListenersAllowedRoutesNamespacesSelector" = {

      options = {
        "matchExpressions" = mkOption {
          description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
          type = types.nullOr (
            types.listOf (
              submoduleOf "gateway.networking.k8s.io.v1beta1.GatewaySpecListenersAllowedRoutesNamespacesSelectorMatchExpressions"
            )
          );
        };
        "matchLabels" = mkOption {
          description = "matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels\nmap is equivalent to an element of matchExpressions, whose key field is \"key\", the\noperator is \"In\", and the values array contains only \"value\". The requirements are ANDed.";
          type = types.nullOr (types.attrsOf types.str);
        };
      };

      config = {
        "matchExpressions" = mkOverride 1002 null;
        "matchLabels" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1beta1.GatewaySpecListenersAllowedRoutesNamespacesSelectorMatchExpressions" =
      {

        options = {
          "key" = mkOption {
            description = "key is the label key that the selector applies to.";
            type = types.str;
          };
          "operator" = mkOption {
            description = "operator represents a key's relationship to a set of values.\nValid operators are In, NotIn, Exists and DoesNotExist.";
            type = types.str;
          };
          "values" = mkOption {
            description = "values is an array of string values. If the operator is In or NotIn,\nthe values array must be non-empty. If the operator is Exists or DoesNotExist,\nthe values array must be empty. This array is replaced during a strategic\nmerge patch.";
            type = types.nullOr (types.listOf types.str);
          };
        };

        config = {
          "values" = mkOverride 1002 null;
        };

      };
    "gateway.networking.k8s.io.v1beta1.GatewaySpecListenersTls" = {

      options = {
        "certificateRefs" = mkOption {
          description = "CertificateRefs contains a series of references to Kubernetes objects that\ncontains TLS certificates and private keys. These certificates are used to\nestablish a TLS handshake for requests that match the hostname of the\nassociated listener.\n\nA single CertificateRef to a Kubernetes Secret has \"Core\" support.\nImplementations MAY choose to support attaching multiple certificates to\na Listener, but this behavior is implementation-specific.\n\nReferences to a resource in different namespace are invalid UNLESS there\nis a ReferenceGrant in the target namespace that allows the certificate\nto be attached. If a ReferenceGrant does not allow this reference, the\n\"ResolvedRefs\" condition MUST be set to False for this listener with the\n\"RefNotPermitted\" reason.\n\nThis field is required to have at least one element when the mode is set\nto \"Terminate\" (default) and is optional otherwise.\n\nCertificateRefs can reference to standard Kubernetes resources, i.e.\nSecret, or implementation-specific custom resources.\n\nSupport: Core - A single reference to a Kubernetes Secret of type kubernetes.io/tls\n\nSupport: Implementation-specific (More than one reference or other resource types)";
          type = types.nullOr (
            coerceAttrsOfSubmodulesToListByKey
              "gateway.networking.k8s.io.v1beta1.GatewaySpecListenersTlsCertificateRefs"
              "name"
              [ ]
          );
          apply = attrsToList;
        };
        "mode" = mkOption {
          description = "Mode defines the TLS behavior for the TLS session initiated by the client.\nThere are two possible modes:\n\n- Terminate: The TLS session between the downstream client and the\n  Gateway is terminated at the Gateway. This mode requires certificates\n  to be specified in some way, such as populating the certificateRefs\n  field.\n- Passthrough: The TLS session is NOT terminated by the Gateway. This\n  implies that the Gateway can't decipher the TLS stream except for\n  the ClientHello message of the TLS protocol. The certificateRefs field\n  is ignored in this mode.\n\nSupport: Core";
          type = types.nullOr types.str;
        };
        "options" = mkOption {
          description = "Options are a list of key/value pairs to enable extended TLS\nconfiguration for each implementation. For example, configuring the\nminimum TLS version or supported cipher suites.\n\nA set of common keys MAY be defined by the API in the future. To avoid\nany ambiguity, implementation-specific definitions MUST use\ndomain-prefixed names, such as `example.com/my-custom-option`.\nUn-prefixed names are reserved for key names defined by Gateway API.\n\nSupport: Implementation-specific";
          type = types.nullOr (types.attrsOf types.str);
        };
      };

      config = {
        "certificateRefs" = mkOverride 1002 null;
        "mode" = mkOverride 1002 null;
        "options" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1beta1.GatewaySpecListenersTlsCertificateRefs" = {

      options = {
        "group" = mkOption {
          description = "Group is the group of the referent. For example, \"gateway.networking.k8s.io\".\nWhen unspecified or empty string, core API group is inferred.";
          type = types.nullOr types.str;
        };
        "kind" = mkOption {
          description = "Kind is kind of the referent. For example \"Secret\".";
          type = types.nullOr types.str;
        };
        "name" = mkOption {
          description = "Name is the name of the referent.";
          type = types.str;
        };
        "namespace" = mkOption {
          description = "Namespace is the namespace of the referenced object. When unspecified, the local\nnamespace is inferred.\n\nNote that when a namespace different than the local namespace is specified,\na ReferenceGrant object is required in the referent namespace to allow that\nnamespace's owner to accept the reference. See the ReferenceGrant\ndocumentation for details.\n\nSupport: Core";
          type = types.nullOr types.str;
        };
      };

      config = {
        "group" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1beta1.GatewayStatus" = {

      options = {
        "addresses" = mkOption {
          description = "Addresses lists the network addresses that have been bound to the\nGateway.\n\nThis list may differ from the addresses provided in the spec under some\nconditions:\n\n  * no addresses are specified, all addresses are dynamically assigned\n  * a combination of specified and dynamic addresses are assigned\n  * a specified address was unusable (e.g. already in use)";
          type = types.nullOr (
            types.listOf (submoduleOf "gateway.networking.k8s.io.v1beta1.GatewayStatusAddresses")
          );
        };
        "conditions" = mkOption {
          description = "Conditions describe the current conditions of the Gateway.\n\nImplementations should prefer to express Gateway conditions\nusing the `GatewayConditionType` and `GatewayConditionReason`\nconstants so that operators and tools can converge on a common\nvocabulary to describe Gateway state.\n\nKnown condition types are:\n\n* \"Accepted\"\n* \"Programmed\"\n* \"Ready\"";
          type = types.nullOr (
            types.listOf (submoduleOf "gateway.networking.k8s.io.v1beta1.GatewayStatusConditions")
          );
        };
        "listeners" = mkOption {
          description = "Listeners provide status for each unique listener port defined in the Spec.";
          type = types.nullOr (
            coerceAttrsOfSubmodulesToListByKey "gateway.networking.k8s.io.v1beta1.GatewayStatusListeners" "name"
              [ "name" ]
          );
          apply = attrsToList;
        };
      };

      config = {
        "addresses" = mkOverride 1002 null;
        "conditions" = mkOverride 1002 null;
        "listeners" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1beta1.GatewayStatusAddresses" = {

      options = {
        "type" = mkOption {
          description = "Type of the address.";
          type = types.nullOr types.str;
        };
        "value" = mkOption {
          description = "Value of the address. The validity of the values will depend\non the type and support by the controller.\n\nExamples: `1.2.3.4`, `128::1`, `my-ip-address`.";
          type = types.str;
        };
      };

      config = {
        "type" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1beta1.GatewayStatusConditions" = {

      options = {
        "lastTransitionTime" = mkOption {
          description = "lastTransitionTime is the last time the condition transitioned from one status to another.\nThis should be when the underlying condition changed.  If that is not known, then using the time when the API field changed is acceptable.";
          type = types.str;
        };
        "message" = mkOption {
          description = "message is a human readable message indicating details about the transition.\nThis may be an empty string.";
          type = types.str;
        };
        "observedGeneration" = mkOption {
          description = "observedGeneration represents the .metadata.generation that the condition was set based upon.\nFor instance, if .metadata.generation is currently 12, but the .status.conditions[x].observedGeneration is 9, the condition is out of date\nwith respect to the current state of the instance.";
          type = types.nullOr types.int;
        };
        "reason" = mkOption {
          description = "reason contains a programmatic identifier indicating the reason for the condition's last transition.\nProducers of specific condition types may define expected values and meanings for this field,\nand whether the values are considered a guaranteed API.\nThe value should be a CamelCase string.\nThis field may not be empty.";
          type = types.str;
        };
        "status" = mkOption {
          description = "status of the condition, one of True, False, Unknown.";
          type = types.str;
        };
        "type" = mkOption {
          description = "type of condition in CamelCase or in foo.example.com/CamelCase.";
          type = types.str;
        };
      };

      config = {
        "observedGeneration" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1beta1.GatewayStatusListeners" = {

      options = {
        "attachedRoutes" = mkOption {
          description = "AttachedRoutes represents the total number of Routes that have been\nsuccessfully attached to this Listener.\n\nSuccessful attachment of a Route to a Listener is based solely on the\ncombination of the AllowedRoutes field on the corresponding Listener\nand the Route's ParentRefs field. A Route is successfully attached to\na Listener when it is selected by the Listener's AllowedRoutes field\nAND the Route has a valid ParentRef selecting the whole Gateway\nresource or a specific Listener as a parent resource (more detail on\nattachment semantics can be found in the documentation on the various\nRoute kinds ParentRefs fields). Listener or Route status does not impact\nsuccessful attachment, i.e. the AttachedRoutes field count MUST be set\nfor Listeners with condition Accepted: false and MUST count successfully\nattached Routes that may themselves have Accepted: false conditions.\n\nUses for this field include troubleshooting Route attachment and\nmeasuring blast radius/impact of changes to a Listener.";
          type = types.int;
        };
        "conditions" = mkOption {
          description = "Conditions describe the current condition of this listener.";
          type = types.listOf (
            submoduleOf "gateway.networking.k8s.io.v1beta1.GatewayStatusListenersConditions"
          );
        };
        "name" = mkOption {
          description = "Name is the name of the Listener that this status corresponds to.";
          type = types.str;
        };
        "supportedKinds" = mkOption {
          description = "SupportedKinds is the list indicating the Kinds supported by this\nlistener. This MUST represent the kinds an implementation supports for\nthat Listener configuration.\n\nIf kinds are specified in Spec that are not supported, they MUST NOT\nappear in this list and an implementation MUST set the \"ResolvedRefs\"\ncondition to \"False\" with the \"InvalidRouteKinds\" reason. If both valid\nand invalid Route kinds are specified, the implementation MUST\nreference the valid Route kinds that have been specified.";
          type = types.listOf (
            submoduleOf "gateway.networking.k8s.io.v1beta1.GatewayStatusListenersSupportedKinds"
          );
        };
      };

      config = { };

    };
    "gateway.networking.k8s.io.v1beta1.GatewayStatusListenersConditions" = {

      options = {
        "lastTransitionTime" = mkOption {
          description = "lastTransitionTime is the last time the condition transitioned from one status to another.\nThis should be when the underlying condition changed.  If that is not known, then using the time when the API field changed is acceptable.";
          type = types.str;
        };
        "message" = mkOption {
          description = "message is a human readable message indicating details about the transition.\nThis may be an empty string.";
          type = types.str;
        };
        "observedGeneration" = mkOption {
          description = "observedGeneration represents the .metadata.generation that the condition was set based upon.\nFor instance, if .metadata.generation is currently 12, but the .status.conditions[x].observedGeneration is 9, the condition is out of date\nwith respect to the current state of the instance.";
          type = types.nullOr types.int;
        };
        "reason" = mkOption {
          description = "reason contains a programmatic identifier indicating the reason for the condition's last transition.\nProducers of specific condition types may define expected values and meanings for this field,\nand whether the values are considered a guaranteed API.\nThe value should be a CamelCase string.\nThis field may not be empty.";
          type = types.str;
        };
        "status" = mkOption {
          description = "status of the condition, one of True, False, Unknown.";
          type = types.str;
        };
        "type" = mkOption {
          description = "type of condition in CamelCase or in foo.example.com/CamelCase.";
          type = types.str;
        };
      };

      config = {
        "observedGeneration" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1beta1.GatewayStatusListenersSupportedKinds" = {

      options = {
        "group" = mkOption {
          description = "Group is the group of the Route.";
          type = types.nullOr types.str;
        };
        "kind" = mkOption {
          description = "Kind is the kind of the Route.";
          type = types.str;
        };
      };

      config = {
        "group" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1beta1.HTTPRoute" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object.\nServers should convert recognized schemas to the latest internal value, and\nmay reject unrecognized values.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = types.nullOr types.str;
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents.\nServers may infer this from the endpoint the client submits requests to.\nCannot be updated.\nIn CamelCase.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = types.nullOr types.str;
        };
        "metadata" = mkOption {
          description = "Standard object's metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = types.nullOr (globalSubmoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta");
        };
        "spec" = mkOption {
          description = "Spec defines the desired state of HTTPRoute.";
          type = submoduleOf "gateway.networking.k8s.io.v1beta1.HTTPRouteSpec";
        };
        "status" = mkOption {
          description = "Status defines the current state of HTTPRoute.";
          type = types.nullOr (submoduleOf "gateway.networking.k8s.io.v1beta1.HTTPRouteStatus");
        };
      };

      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1beta1.HTTPRouteSpec" = {

      options = {
        "hostnames" = mkOption {
          description = "Hostnames defines a set of hostnames that should match against the HTTP Host\nheader to select a HTTPRoute used to process the request. Implementations\nMUST ignore any port value specified in the HTTP Host header while\nperforming a match and (absent of any applicable header modification\nconfiguration) MUST forward this header unmodified to the backend.\n\nValid values for Hostnames are determined by RFC 1123 definition of a\nhostname with 2 notable exceptions:\n\n1. IPs are not allowed.\n2. A hostname may be prefixed with a wildcard label (`*.`). The wildcard\n   label must appear by itself as the first label.\n\nIf a hostname is specified by both the Listener and HTTPRoute, there\nmust be at least one intersecting hostname for the HTTPRoute to be\nattached to the Listener. For example:\n\n* A Listener with `test.example.com` as the hostname matches HTTPRoutes\n  that have either not specified any hostnames, or have specified at\n  least one of `test.example.com` or `*.example.com`.\n* A Listener with `*.example.com` as the hostname matches HTTPRoutes\n  that have either not specified any hostnames or have specified at least\n  one hostname that matches the Listener hostname. For example,\n  `*.example.com`, `test.example.com`, and `foo.test.example.com` would\n  all match. On the other hand, `example.com` and `test.example.net` would\n  not match.\n\nHostnames that are prefixed with a wildcard label (`*.`) are interpreted\nas a suffix match. That means that a match for `*.example.com` would match\nboth `test.example.com`, and `foo.test.example.com`, but not `example.com`.\n\nIf both the Listener and HTTPRoute have specified hostnames, any\nHTTPRoute hostnames that do not match the Listener hostname MUST be\nignored. For example, if a Listener specified `*.example.com`, and the\nHTTPRoute specified `test.example.com` and `test.example.net`,\n`test.example.net` must not be considered for a match.\n\nIf both the Listener and HTTPRoute have specified hostnames, and none\nmatch with the criteria above, then the HTTPRoute is not accepted. The\nimplementation must raise an 'Accepted' Condition with a status of\n`False` in the corresponding RouteParentStatus.\n\nIn the event that multiple HTTPRoutes specify intersecting hostnames (e.g.\noverlapping wildcard matching and exact matching hostnames), precedence must\nbe given to rules from the HTTPRoute with the largest number of:\n\n* Characters in a matching non-wildcard hostname.\n* Characters in a matching hostname.\n\nIf ties exist across multiple Routes, the matching precedence rules for\nHTTPRouteMatches takes over.\n\nSupport: Core";
          type = types.nullOr (types.listOf types.str);
        };
        "parentRefs" = mkOption {
          description = "ParentRefs references the resources (usually Gateways) that a Route wants\nto be attached to. Note that the referenced parent resource needs to\nallow this for the attachment to be complete. For Gateways, that means\nthe Gateway needs to allow attachment from Routes of this kind and\nnamespace. For Services, that means the Service must either be in the same\nnamespace for a \"producer\" route, or the mesh implementation must support\nand allow \"consumer\" routes for the referenced Service. ReferenceGrant is\nnot applicable for governing ParentRefs to Services - it is not possible to\ncreate a \"producer\" route for a Service in a different namespace from the\nRoute.\n\nThere are two kinds of parent resources with \"Core\" support:\n\n* Gateway (Gateway conformance profile)\n* Service (Mesh conformance profile, ClusterIP Services only)\n\nThis API may be extended in the future to support additional kinds of parent\nresources.\n\nParentRefs must be _distinct_. This means either that:\n\n* They select different objects.  If this is the case, then parentRef\n  entries are distinct. In terms of fields, this means that the\n  multi-part key defined by `group`, `kind`, `namespace`, and `name` must\n  be unique across all parentRef entries in the Route.\n* They do not select different objects, but for each optional field used,\n  each ParentRef that selects the same object must set the same set of\n  optional fields to different values. If one ParentRef sets a\n  combination of optional fields, all must set the same combination.\n\nSome examples:\n\n* If one ParentRef sets `sectionName`, all ParentRefs referencing the\n  same object must also set `sectionName`.\n* If one ParentRef sets `port`, all ParentRefs referencing the same\n  object must also set `port`.\n* If one ParentRef sets `sectionName` and `port`, all ParentRefs\n  referencing the same object must also set `sectionName` and `port`.\n\nIt is possible to separately reference multiple distinct objects that may\nbe collapsed by an implementation. For example, some implementations may\nchoose to merge compatible Gateway Listeners together. If that is the\ncase, the list of routes attached to those resources should also be\nmerged.\n\nNote that for ParentRefs that cross namespace boundaries, there are specific\nrules. Cross-namespace references are only valid if they are explicitly\nallowed by something in the namespace they are referring to. For example,\nGateway has the AllowedRoutes field, and ReferenceGrant provides a\ngeneric way to enable other kinds of cross-namespace reference.";
          type = types.nullOr (
            coerceAttrsOfSubmodulesToListByKey "gateway.networking.k8s.io.v1beta1.HTTPRouteSpecParentRefs"
              "name"
              [ ]
          );
          apply = attrsToList;
        };
        "rules" = mkOption {
          description = "Rules are a list of HTTP matchers, filters and actions.";
          type = types.nullOr (
            coerceAttrsOfSubmodulesToListByKey "gateway.networking.k8s.io.v1beta1.HTTPRouteSpecRules" "name" [ ]
          );
          apply = attrsToList;
        };
      };

      config = {
        "hostnames" = mkOverride 1002 null;
        "parentRefs" = mkOverride 1002 null;
        "rules" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1beta1.HTTPRouteSpecParentRefs" = {

      options = {
        "group" = mkOption {
          description = "Group is the group of the referent.\nWhen unspecified, \"gateway.networking.k8s.io\" is inferred.\nTo set the core API group (such as for a \"Service\" kind referent),\nGroup must be explicitly set to \"\" (empty string).\n\nSupport: Core";
          type = types.nullOr types.str;
        };
        "kind" = mkOption {
          description = "Kind is kind of the referent.\n\nThere are two kinds of parent resources with \"Core\" support:\n\n* Gateway (Gateway conformance profile)\n* Service (Mesh conformance profile, ClusterIP Services only)\n\nSupport for other resources is Implementation-Specific.";
          type = types.nullOr types.str;
        };
        "name" = mkOption {
          description = "Name is the name of the referent.\n\nSupport: Core";
          type = types.str;
        };
        "namespace" = mkOption {
          description = "Namespace is the namespace of the referent. When unspecified, this refers\nto the local namespace of the Route.\n\nNote that there are specific rules for ParentRefs which cross namespace\nboundaries. Cross-namespace references are only valid if they are explicitly\nallowed by something in the namespace they are referring to. For example:\nGateway has the AllowedRoutes field, and ReferenceGrant provides a\ngeneric way to enable any other kind of cross-namespace reference.\n\nSupport: Core";
          type = types.nullOr types.str;
        };
        "port" = mkOption {
          description = "Port is the network port this Route targets. It can be interpreted\ndifferently based on the type of parent resource.\n\nWhen the parent resource is a Gateway, this targets all listeners\nlistening on the specified port that also support this kind of Route(and\nselect this Route). It's not recommended to set `Port` unless the\nnetworking behaviors specified in a Route must apply to a specific port\nas opposed to a listener(s) whose port(s) may be changed. When both Port\nand SectionName are specified, the name and port of the selected listener\nmust match both specified values.\n\nImplementations MAY choose to support other parent resources.\nImplementations supporting other types of parent resources MUST clearly\ndocument how/if Port is interpreted.\n\nFor the purpose of status, an attachment is considered successful as\nlong as the parent resource accepts it partially. For example, Gateway\nlisteners can restrict which Routes can attach to them by Route kind,\nnamespace, or hostname. If 1 of 2 Gateway listeners accept attachment\nfrom the referencing Route, the Route MUST be considered successfully\nattached. If no Gateway listeners accept attachment from this Route,\nthe Route MUST be considered detached from the Gateway.\n\nSupport: Extended";
          type = types.nullOr types.int;
        };
        "sectionName" = mkOption {
          description = "SectionName is the name of a section within the target resource. In the\nfollowing resources, SectionName is interpreted as the following:\n\n* Gateway: Listener name. When both Port (experimental) and SectionName\nare specified, the name and port of the selected listener must match\nboth specified values.\n* Service: Port name. When both Port (experimental) and SectionName\nare specified, the name and port of the selected listener must match\nboth specified values.\n\nImplementations MAY choose to support attaching Routes to other resources.\nIf that is the case, they MUST clearly document how SectionName is\ninterpreted.\n\nWhen unspecified (empty string), this will reference the entire resource.\nFor the purpose of status, an attachment is considered successful if at\nleast one section in the parent resource accepts it. For example, Gateway\nlisteners can restrict which Routes can attach to them by Route kind,\nnamespace, or hostname. If 1 of 2 Gateway listeners accept attachment from\nthe referencing Route, the Route MUST be considered successfully\nattached. If no Gateway listeners accept attachment from this Route, the\nRoute MUST be considered detached from the Gateway.\n\nSupport: Core";
          type = types.nullOr types.str;
        };
      };

      config = {
        "group" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
        "port" = mkOverride 1002 null;
        "sectionName" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1beta1.HTTPRouteSpecRules" = {

      options = {
        "backendRefs" = mkOption {
          description = "BackendRefs defines the backend(s) where matching requests should be\nsent.\n\nFailure behavior here depends on how many BackendRefs are specified and\nhow many are invalid.\n\nIf *all* entries in BackendRefs are invalid, and there are also no filters\nspecified in this route rule, *all* traffic which matches this rule MUST\nreceive a 500 status code.\n\nSee the HTTPBackendRef definition for the rules about what makes a single\nHTTPBackendRef invalid.\n\nWhen a HTTPBackendRef is invalid, 500 status codes MUST be returned for\nrequests that would have otherwise been routed to an invalid backend. If\nmultiple backends are specified, and some are invalid, the proportion of\nrequests that would otherwise have been routed to an invalid backend\nMUST receive a 500 status code.\n\nFor example, if two backends are specified with equal weights, and one is\ninvalid, 50 percent of traffic must receive a 500. Implementations may\nchoose how that 50 percent is determined.\n\nWhen a HTTPBackendRef refers to a Service that has no ready endpoints,\nimplementations SHOULD return a 503 for requests to that backend instead.\nIf an implementation chooses to do this, all of the above rules for 500 responses\nMUST also apply for responses that return a 503.\n\nSupport: Core for Kubernetes Service\n\nSupport: Extended for Kubernetes ServiceImport\n\nSupport: Implementation-specific for any other resource\n\nSupport for weight: Core";
          type = types.nullOr (
            coerceAttrsOfSubmodulesToListByKey "gateway.networking.k8s.io.v1beta1.HTTPRouteSpecRulesBackendRefs"
              "name"
              [ ]
          );
          apply = attrsToList;
        };
        "filters" = mkOption {
          description = "Filters define the filters that are applied to requests that match\nthis rule.\n\nWherever possible, implementations SHOULD implement filters in the order\nthey are specified.\n\nImplementations MAY choose to implement this ordering strictly, rejecting\nany combination or order of filters that cannot be supported. If implementations\nchoose a strict interpretation of filter ordering, they MUST clearly document\nthat behavior.\n\nTo reject an invalid combination or order of filters, implementations SHOULD\nconsider the Route Rules with this configuration invalid. If all Route Rules\nin a Route are invalid, the entire Route would be considered invalid. If only\na portion of Route Rules are invalid, implementations MUST set the\n\"PartiallyInvalid\" condition for the Route.\n\nConformance-levels at this level are defined based on the type of filter:\n\n- ALL core filters MUST be supported by all implementations.\n- Implementers are encouraged to support extended filters.\n- Implementation-specific custom filters have no API guarantees across\n  implementations.\n\nSpecifying the same filter multiple times is not supported unless explicitly\nindicated in the filter.\n\nAll filters are expected to be compatible with each other except for the\nURLRewrite and RequestRedirect filters, which may not be combined. If an\nimplementation cannot support other combinations of filters, they must clearly\ndocument that limitation. In cases where incompatible or unsupported\nfilters are specified and cause the `Accepted` condition to be set to status\n`False`, implementations may use the `IncompatibleFilters` reason to specify\nthis configuration error.\n\nSupport: Core";
          type = types.nullOr (
            types.listOf (submoduleOf "gateway.networking.k8s.io.v1beta1.HTTPRouteSpecRulesFilters")
          );
        };
        "matches" = mkOption {
          description = "Matches define conditions used for matching the rule against incoming\nHTTP requests. Each match is independent, i.e. this rule will be matched\nif **any** one of the matches is satisfied.\n\nFor example, take the following matches configuration:\n\n```\nmatches:\n- path:\n    value: \"/foo\"\n  headers:\n  - name: \"version\"\n    value: \"v2\"\n- path:\n    value: \"/v2/foo\"\n```\n\nFor a request to match against this rule, a request must satisfy\nEITHER of the two conditions:\n\n- path prefixed with `/foo` AND contains the header `version: v2`\n- path prefix of `/v2/foo`\n\nSee the documentation for HTTPRouteMatch on how to specify multiple\nmatch conditions that should be ANDed together.\n\nIf no matches are specified, the default is a prefix\npath match on \"/\", which has the effect of matching every\nHTTP request.\n\nProxy or Load Balancer routing configuration generated from HTTPRoutes\nMUST prioritize matches based on the following criteria, continuing on\nties. Across all rules specified on applicable Routes, precedence must be\ngiven to the match having:\n\n* \"Exact\" path match.\n* \"Prefix\" path match with largest number of characters.\n* Method match.\n* Largest number of header matches.\n* Largest number of query param matches.\n\nNote: The precedence of RegularExpression path matches are implementation-specific.\n\nIf ties still exist across multiple Routes, matching precedence MUST be\ndetermined in order of the following criteria, continuing on ties:\n\n* The oldest Route based on creation timestamp.\n* The Route appearing first in alphabetical order by\n  \"{namespace}/{name}\".\n\nIf ties still exist within an HTTPRoute, matching precedence MUST be granted\nto the FIRST matching rule (in list order) with a match meeting the above\ncriteria.\n\nWhen no rules matching a request have been successfully attached to the\nparent a request is coming from, a HTTP 404 status code MUST be returned.";
          type = types.nullOr (
            types.listOf (submoduleOf "gateway.networking.k8s.io.v1beta1.HTTPRouteSpecRulesMatches")
          );
        };
        "name" = mkOption {
          description = "Name is the name of the route rule. This name MUST be unique within a Route if it is set.\n\nSupport: Extended";
          type = types.nullOr types.str;
        };
        "timeouts" = mkOption {
          description = "Timeouts defines the timeouts that can be configured for an HTTP request.\n\nSupport: Extended";
          type = types.nullOr (submoduleOf "gateway.networking.k8s.io.v1beta1.HTTPRouteSpecRulesTimeouts");
        };
      };

      config = {
        "backendRefs" = mkOverride 1002 null;
        "filters" = mkOverride 1002 null;
        "matches" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "timeouts" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1beta1.HTTPRouteSpecRulesBackendRefs" = {

      options = {
        "filters" = mkOption {
          description = "Filters defined at this level should be executed if and only if the\nrequest is being forwarded to the backend defined here.\n\nSupport: Implementation-specific (For broader support of filters, use the\nFilters field in HTTPRouteRule.)";
          type = types.nullOr (
            types.listOf (submoduleOf "gateway.networking.k8s.io.v1beta1.HTTPRouteSpecRulesBackendRefsFilters")
          );
        };
        "group" = mkOption {
          description = "Group is the group of the referent. For example, \"gateway.networking.k8s.io\".\nWhen unspecified or empty string, core API group is inferred.";
          type = types.nullOr types.str;
        };
        "kind" = mkOption {
          description = "Kind is the Kubernetes resource kind of the referent. For example\n\"Service\".\n\nDefaults to \"Service\" when not specified.\n\nExternalName services can refer to CNAME DNS records that may live\noutside of the cluster and as such are difficult to reason about in\nterms of conformance. They also may not be safe to forward to (see\nCVE-2021-25740 for more information). Implementations SHOULD NOT\nsupport ExternalName Services.\n\nSupport: Core (Services with a type other than ExternalName)\n\nSupport: Implementation-specific (Services with type ExternalName)";
          type = types.nullOr types.str;
        };
        "name" = mkOption {
          description = "Name is the name of the referent.";
          type = types.str;
        };
        "namespace" = mkOption {
          description = "Namespace is the namespace of the backend. When unspecified, the local\nnamespace is inferred.\n\nNote that when a namespace different than the local namespace is specified,\na ReferenceGrant object is required in the referent namespace to allow that\nnamespace's owner to accept the reference. See the ReferenceGrant\ndocumentation for details.\n\nSupport: Core";
          type = types.nullOr types.str;
        };
        "port" = mkOption {
          description = "Port specifies the destination port number to use for this resource.\nPort is required when the referent is a Kubernetes Service. In this\ncase, the port number is the service port number, not the target port.\nFor other resources, destination port might be derived from the referent\nresource or this field.";
          type = types.nullOr types.int;
        };
        "weight" = mkOption {
          description = "Weight specifies the proportion of requests forwarded to the referenced\nbackend. This is computed as weight/(sum of all weights in this\nBackendRefs list). For non-zero values, there may be some epsilon from\nthe exact proportion defined here depending on the precision an\nimplementation supports. Weight is not a percentage and the sum of\nweights does not need to equal 100.\n\nIf only one backend is specified and it has a weight greater than 0, 100%\nof the traffic is forwarded to that backend. If weight is set to 0, no\ntraffic should be forwarded for this entry. If unspecified, weight\ndefaults to 1.\n\nSupport for this field varies based on the context where used.";
          type = types.nullOr types.int;
        };
      };

      config = {
        "filters" = mkOverride 1002 null;
        "group" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
        "port" = mkOverride 1002 null;
        "weight" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1beta1.HTTPRouteSpecRulesBackendRefsFilters" = {

      options = {
        "extensionRef" = mkOption {
          description = "ExtensionRef is an optional, implementation-specific extension to the\n\"filter\" behavior.  For example, resource \"myroutefilter\" in group\n\"networking.example.net\"). ExtensionRef MUST NOT be used for core and\nextended filters.\n\nThis filter can be used multiple times within the same rule.\n\nSupport: Implementation-specific";
          type = types.nullOr (
            submoduleOf "gateway.networking.k8s.io.v1beta1.HTTPRouteSpecRulesBackendRefsFiltersExtensionRef"
          );
        };
        "requestHeaderModifier" = mkOption {
          description = "RequestHeaderModifier defines a schema for a filter that modifies request\nheaders.\n\nSupport: Core";
          type = types.nullOr (
            submoduleOf "gateway.networking.k8s.io.v1beta1.HTTPRouteSpecRulesBackendRefsFiltersRequestHeaderModifier"
          );
        };
        "requestMirror" = mkOption {
          description = "RequestMirror defines a schema for a filter that mirrors requests.\nRequests are sent to the specified destination, but responses from\nthat destination are ignored.\n\nThis filter can be used multiple times within the same rule. Note that\nnot all implementations will be able to support mirroring to multiple\nbackends.\n\nSupport: Extended";
          type = types.nullOr (
            submoduleOf "gateway.networking.k8s.io.v1beta1.HTTPRouteSpecRulesBackendRefsFiltersRequestMirror"
          );
        };
        "requestRedirect" = mkOption {
          description = "RequestRedirect defines a schema for a filter that responds to the\nrequest with an HTTP redirection.\n\nSupport: Core";
          type = types.nullOr (
            submoduleOf "gateway.networking.k8s.io.v1beta1.HTTPRouteSpecRulesBackendRefsFiltersRequestRedirect"
          );
        };
        "responseHeaderModifier" = mkOption {
          description = "ResponseHeaderModifier defines a schema for a filter that modifies response\nheaders.\n\nSupport: Extended";
          type = types.nullOr (
            submoduleOf "gateway.networking.k8s.io.v1beta1.HTTPRouteSpecRulesBackendRefsFiltersResponseHeaderModifier"
          );
        };
        "type" = mkOption {
          description = "Type identifies the type of filter to apply. As with other API fields,\ntypes are classified into three conformance levels:\n\n- Core: Filter types and their corresponding configuration defined by\n  \"Support: Core\" in this package, e.g. \"RequestHeaderModifier\". All\n  implementations must support core filters.\n\n- Extended: Filter types and their corresponding configuration defined by\n  \"Support: Extended\" in this package, e.g. \"RequestMirror\". Implementers\n  are encouraged to support extended filters.\n\n- Implementation-specific: Filters that are defined and supported by\n  specific vendors.\n  In the future, filters showing convergence in behavior across multiple\n  implementations will be considered for inclusion in extended or core\n  conformance levels. Filter-specific configuration for such filters\n  is specified using the ExtensionRef field. `Type` should be set to\n  \"ExtensionRef\" for custom filters.\n\nImplementers are encouraged to define custom implementation types to\nextend the core API with implementation-specific behavior.\n\nIf a reference to a custom filter type cannot be resolved, the filter\nMUST NOT be skipped. Instead, requests that would have been processed by\nthat filter MUST receive a HTTP error response.\n\nNote that values may be added to this enum, implementations\nmust ensure that unknown values will not cause a crash.\n\nUnknown values here must result in the implementation setting the\nAccepted Condition for the Route to `status: False`, with a\nReason of `UnsupportedValue`.";
          type = types.str;
        };
        "urlRewrite" = mkOption {
          description = "URLRewrite defines a schema for a filter that modifies a request during forwarding.\n\nSupport: Extended";
          type = types.nullOr (
            submoduleOf "gateway.networking.k8s.io.v1beta1.HTTPRouteSpecRulesBackendRefsFiltersUrlRewrite"
          );
        };
      };

      config = {
        "extensionRef" = mkOverride 1002 null;
        "requestHeaderModifier" = mkOverride 1002 null;
        "requestMirror" = mkOverride 1002 null;
        "requestRedirect" = mkOverride 1002 null;
        "responseHeaderModifier" = mkOverride 1002 null;
        "urlRewrite" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1beta1.HTTPRouteSpecRulesBackendRefsFiltersExtensionRef" = {

      options = {
        "group" = mkOption {
          description = "Group is the group of the referent. For example, \"gateway.networking.k8s.io\".\nWhen unspecified or empty string, core API group is inferred.";
          type = types.str;
        };
        "kind" = mkOption {
          description = "Kind is kind of the referent. For example \"HTTPRoute\" or \"Service\".";
          type = types.str;
        };
        "name" = mkOption {
          description = "Name is the name of the referent.";
          type = types.str;
        };
      };

      config = { };

    };
    "gateway.networking.k8s.io.v1beta1.HTTPRouteSpecRulesBackendRefsFiltersRequestHeaderModifier" = {

      options = {
        "add" = mkOption {
          description = "Add adds the given header(s) (name, value) to the request\nbefore the action. It appends to any existing values associated\nwith the header name.\n\nInput:\n  GET /foo HTTP/1.1\n  my-header: foo\n\nConfig:\n  add:\n  - name: \"my-header\"\n    value: \"bar,baz\"\n\nOutput:\n  GET /foo HTTP/1.1\n  my-header: foo,bar,baz";
          type = types.nullOr (
            coerceAttrsOfSubmodulesToListByKey
              "gateway.networking.k8s.io.v1beta1.HTTPRouteSpecRulesBackendRefsFiltersRequestHeaderModifierAdd"
              "name"
              [ "name" ]
          );
          apply = attrsToList;
        };
        "remove" = mkOption {
          description = "Remove the given header(s) from the HTTP request before the action. The\nvalue of Remove is a list of HTTP header names. Note that the header\nnames are case-insensitive (see\nhttps://datatracker.ietf.org/doc/html/rfc2616#section-4.2).\n\nInput:\n  GET /foo HTTP/1.1\n  my-header1: foo\n  my-header2: bar\n  my-header3: baz\n\nConfig:\n  remove: [\"my-header1\", \"my-header3\"]\n\nOutput:\n  GET /foo HTTP/1.1\n  my-header2: bar";
          type = types.nullOr (types.listOf types.str);
        };
        "set" = mkOption {
          description = "Set overwrites the request with the given header (name, value)\nbefore the action.\n\nInput:\n  GET /foo HTTP/1.1\n  my-header: foo\n\nConfig:\n  set:\n  - name: \"my-header\"\n    value: \"bar\"\n\nOutput:\n  GET /foo HTTP/1.1\n  my-header: bar";
          type = types.nullOr (
            coerceAttrsOfSubmodulesToListByKey
              "gateway.networking.k8s.io.v1beta1.HTTPRouteSpecRulesBackendRefsFiltersRequestHeaderModifierSet"
              "name"
              [ "name" ]
          );
          apply = attrsToList;
        };
      };

      config = {
        "add" = mkOverride 1002 null;
        "remove" = mkOverride 1002 null;
        "set" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1beta1.HTTPRouteSpecRulesBackendRefsFiltersRequestHeaderModifierAdd" = {

      options = {
        "name" = mkOption {
          description = "Name is the name of the HTTP Header to be matched. Name matching MUST be\ncase-insensitive. (See https://tools.ietf.org/html/rfc7230#section-3.2).\n\nIf multiple entries specify equivalent header names, the first entry with\nan equivalent name MUST be considered for a match. Subsequent entries\nwith an equivalent header name MUST be ignored. Due to the\ncase-insensitivity of header names, \"foo\" and \"Foo\" are considered\nequivalent.";
          type = types.str;
        };
        "value" = mkOption {
          description = "Value is the value of HTTP Header to be matched.";
          type = types.str;
        };
      };

      config = { };

    };
    "gateway.networking.k8s.io.v1beta1.HTTPRouteSpecRulesBackendRefsFiltersRequestHeaderModifierSet" = {

      options = {
        "name" = mkOption {
          description = "Name is the name of the HTTP Header to be matched. Name matching MUST be\ncase-insensitive. (See https://tools.ietf.org/html/rfc7230#section-3.2).\n\nIf multiple entries specify equivalent header names, the first entry with\nan equivalent name MUST be considered for a match. Subsequent entries\nwith an equivalent header name MUST be ignored. Due to the\ncase-insensitivity of header names, \"foo\" and \"Foo\" are considered\nequivalent.";
          type = types.str;
        };
        "value" = mkOption {
          description = "Value is the value of HTTP Header to be matched.";
          type = types.str;
        };
      };

      config = { };

    };
    "gateway.networking.k8s.io.v1beta1.HTTPRouteSpecRulesBackendRefsFiltersRequestMirror" = {

      options = {
        "backendRef" = mkOption {
          description = "BackendRef references a resource where mirrored requests are sent.\n\nMirrored requests must be sent only to a single destination endpoint\nwithin this BackendRef, irrespective of how many endpoints are present\nwithin this BackendRef.\n\nIf the referent cannot be found, this BackendRef is invalid and must be\ndropped from the Gateway. The controller must ensure the \"ResolvedRefs\"\ncondition on the Route status is set to `status: False` and not configure\nthis backend in the underlying implementation.\n\nIf there is a cross-namespace reference to an *existing* object\nthat is not allowed by a ReferenceGrant, the controller must ensure the\n\"ResolvedRefs\"  condition on the Route is set to `status: False`,\nwith the \"RefNotPermitted\" reason and not configure this backend in the\nunderlying implementation.\n\nIn either error case, the Message of the `ResolvedRefs` Condition\nshould be used to provide more detail about the problem.\n\nSupport: Extended for Kubernetes Service\n\nSupport: Implementation-specific for any other resource";
          type = submoduleOf "gateway.networking.k8s.io.v1beta1.HTTPRouteSpecRulesBackendRefsFiltersRequestMirrorBackendRef";
        };
        "fraction" = mkOption {
          description = "Fraction represents the fraction of requests that should be\nmirrored to BackendRef.\n\nOnly one of Fraction or Percent may be specified. If neither field\nis specified, 100% of requests will be mirrored.";
          type = types.nullOr (
            submoduleOf "gateway.networking.k8s.io.v1beta1.HTTPRouteSpecRulesBackendRefsFiltersRequestMirrorFraction"
          );
        };
        "percent" = mkOption {
          description = "Percent represents the percentage of requests that should be\nmirrored to BackendRef. Its minimum value is 0 (indicating 0% of\nrequests) and its maximum value is 100 (indicating 100% of requests).\n\nOnly one of Fraction or Percent may be specified. If neither field\nis specified, 100% of requests will be mirrored.";
          type = types.nullOr types.int;
        };
      };

      config = {
        "fraction" = mkOverride 1002 null;
        "percent" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1beta1.HTTPRouteSpecRulesBackendRefsFiltersRequestMirrorBackendRef" = {

      options = {
        "group" = mkOption {
          description = "Group is the group of the referent. For example, \"gateway.networking.k8s.io\".\nWhen unspecified or empty string, core API group is inferred.";
          type = types.nullOr types.str;
        };
        "kind" = mkOption {
          description = "Kind is the Kubernetes resource kind of the referent. For example\n\"Service\".\n\nDefaults to \"Service\" when not specified.\n\nExternalName services can refer to CNAME DNS records that may live\noutside of the cluster and as such are difficult to reason about in\nterms of conformance. They also may not be safe to forward to (see\nCVE-2021-25740 for more information). Implementations SHOULD NOT\nsupport ExternalName Services.\n\nSupport: Core (Services with a type other than ExternalName)\n\nSupport: Implementation-specific (Services with type ExternalName)";
          type = types.nullOr types.str;
        };
        "name" = mkOption {
          description = "Name is the name of the referent.";
          type = types.str;
        };
        "namespace" = mkOption {
          description = "Namespace is the namespace of the backend. When unspecified, the local\nnamespace is inferred.\n\nNote that when a namespace different than the local namespace is specified,\na ReferenceGrant object is required in the referent namespace to allow that\nnamespace's owner to accept the reference. See the ReferenceGrant\ndocumentation for details.\n\nSupport: Core";
          type = types.nullOr types.str;
        };
        "port" = mkOption {
          description = "Port specifies the destination port number to use for this resource.\nPort is required when the referent is a Kubernetes Service. In this\ncase, the port number is the service port number, not the target port.\nFor other resources, destination port might be derived from the referent\nresource or this field.";
          type = types.nullOr types.int;
        };
      };

      config = {
        "group" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
        "port" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1beta1.HTTPRouteSpecRulesBackendRefsFiltersRequestMirrorFraction" = {

      options = {
        "denominator" = mkOption {
          description = "";
          type = types.nullOr types.int;
        };
        "numerator" = mkOption {
          description = "";
          type = types.int;
        };
      };

      config = {
        "denominator" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1beta1.HTTPRouteSpecRulesBackendRefsFiltersRequestRedirect" = {

      options = {
        "hostname" = mkOption {
          description = "Hostname is the hostname to be used in the value of the `Location`\nheader in the response.\nWhen empty, the hostname in the `Host` header of the request is used.\n\nSupport: Core";
          type = types.nullOr types.str;
        };
        "path" = mkOption {
          description = "Path defines parameters used to modify the path of the incoming request.\nThe modified path is then used to construct the `Location` header. When\nempty, the request path is used as-is.\n\nSupport: Extended";
          type = types.nullOr (
            submoduleOf "gateway.networking.k8s.io.v1beta1.HTTPRouteSpecRulesBackendRefsFiltersRequestRedirectPath"
          );
        };
        "port" = mkOption {
          description = "Port is the port to be used in the value of the `Location`\nheader in the response.\n\nIf no port is specified, the redirect port MUST be derived using the\nfollowing rules:\n\n* If redirect scheme is not-empty, the redirect port MUST be the well-known\n  port associated with the redirect scheme. Specifically \"http\" to port 80\n  and \"https\" to port 443. If the redirect scheme does not have a\n  well-known port, the listener port of the Gateway SHOULD be used.\n* If redirect scheme is empty, the redirect port MUST be the Gateway\n  Listener port.\n\nImplementations SHOULD NOT add the port number in the 'Location'\nheader in the following cases:\n\n* A Location header that will use HTTP (whether that is determined via\n  the Listener protocol or the Scheme field) _and_ use port 80.\n* A Location header that will use HTTPS (whether that is determined via\n  the Listener protocol or the Scheme field) _and_ use port 443.\n\nSupport: Extended";
          type = types.nullOr types.int;
        };
        "scheme" = mkOption {
          description = "Scheme is the scheme to be used in the value of the `Location` header in\nthe response. When empty, the scheme of the request is used.\n\nScheme redirects can affect the port of the redirect, for more information,\nrefer to the documentation for the port field of this filter.\n\nNote that values may be added to this enum, implementations\nmust ensure that unknown values will not cause a crash.\n\nUnknown values here must result in the implementation setting the\nAccepted Condition for the Route to `status: False`, with a\nReason of `UnsupportedValue`.\n\nSupport: Extended";
          type = types.nullOr types.str;
        };
        "statusCode" = mkOption {
          description = "StatusCode is the HTTP status code to be used in response.\n\nNote that values may be added to this enum, implementations\nmust ensure that unknown values will not cause a crash.\n\nUnknown values here must result in the implementation setting the\nAccepted Condition for the Route to `status: False`, with a\nReason of `UnsupportedValue`.\n\nSupport: Core";
          type = types.nullOr types.int;
        };
      };

      config = {
        "hostname" = mkOverride 1002 null;
        "path" = mkOverride 1002 null;
        "port" = mkOverride 1002 null;
        "scheme" = mkOverride 1002 null;
        "statusCode" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1beta1.HTTPRouteSpecRulesBackendRefsFiltersRequestRedirectPath" = {

      options = {
        "replaceFullPath" = mkOption {
          description = "ReplaceFullPath specifies the value with which to replace the full path\nof a request during a rewrite or redirect.";
          type = types.nullOr types.str;
        };
        "replacePrefixMatch" = mkOption {
          description = "ReplacePrefixMatch specifies the value with which to replace the prefix\nmatch of a request during a rewrite or redirect. For example, a request\nto \"/foo/bar\" with a prefix match of \"/foo\" and a ReplacePrefixMatch\nof \"/xyz\" would be modified to \"/xyz/bar\".\n\nNote that this matches the behavior of the PathPrefix match type. This\nmatches full path elements. A path element refers to the list of labels\nin the path split by the `/` separator. When specified, a trailing `/` is\nignored. For example, the paths `/abc`, `/abc/`, and `/abc/def` would all\nmatch the prefix `/abc`, but the path `/abcd` would not.\n\nReplacePrefixMatch is only compatible with a `PathPrefix` HTTPRouteMatch.\nUsing any other HTTPRouteMatch type on the same HTTPRouteRule will result in\nthe implementation setting the Accepted Condition for the Route to `status: False`.\n\nRequest Path | Prefix Match | Replace Prefix | Modified Path";
          type = types.nullOr types.str;
        };
        "type" = mkOption {
          description = "Type defines the type of path modifier. Additional types may be\nadded in a future release of the API.\n\nNote that values may be added to this enum, implementations\nmust ensure that unknown values will not cause a crash.\n\nUnknown values here must result in the implementation setting the\nAccepted Condition for the Route to `status: False`, with a\nReason of `UnsupportedValue`.";
          type = types.str;
        };
      };

      config = {
        "replaceFullPath" = mkOverride 1002 null;
        "replacePrefixMatch" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1beta1.HTTPRouteSpecRulesBackendRefsFiltersResponseHeaderModifier" = {

      options = {
        "add" = mkOption {
          description = "Add adds the given header(s) (name, value) to the request\nbefore the action. It appends to any existing values associated\nwith the header name.\n\nInput:\n  GET /foo HTTP/1.1\n  my-header: foo\n\nConfig:\n  add:\n  - name: \"my-header\"\n    value: \"bar,baz\"\n\nOutput:\n  GET /foo HTTP/1.1\n  my-header: foo,bar,baz";
          type = types.nullOr (
            coerceAttrsOfSubmodulesToListByKey
              "gateway.networking.k8s.io.v1beta1.HTTPRouteSpecRulesBackendRefsFiltersResponseHeaderModifierAdd"
              "name"
              [ "name" ]
          );
          apply = attrsToList;
        };
        "remove" = mkOption {
          description = "Remove the given header(s) from the HTTP request before the action. The\nvalue of Remove is a list of HTTP header names. Note that the header\nnames are case-insensitive (see\nhttps://datatracker.ietf.org/doc/html/rfc2616#section-4.2).\n\nInput:\n  GET /foo HTTP/1.1\n  my-header1: foo\n  my-header2: bar\n  my-header3: baz\n\nConfig:\n  remove: [\"my-header1\", \"my-header3\"]\n\nOutput:\n  GET /foo HTTP/1.1\n  my-header2: bar";
          type = types.nullOr (types.listOf types.str);
        };
        "set" = mkOption {
          description = "Set overwrites the request with the given header (name, value)\nbefore the action.\n\nInput:\n  GET /foo HTTP/1.1\n  my-header: foo\n\nConfig:\n  set:\n  - name: \"my-header\"\n    value: \"bar\"\n\nOutput:\n  GET /foo HTTP/1.1\n  my-header: bar";
          type = types.nullOr (
            coerceAttrsOfSubmodulesToListByKey
              "gateway.networking.k8s.io.v1beta1.HTTPRouteSpecRulesBackendRefsFiltersResponseHeaderModifierSet"
              "name"
              [ "name" ]
          );
          apply = attrsToList;
        };
      };

      config = {
        "add" = mkOverride 1002 null;
        "remove" = mkOverride 1002 null;
        "set" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1beta1.HTTPRouteSpecRulesBackendRefsFiltersResponseHeaderModifierAdd" =
      {

        options = {
          "name" = mkOption {
            description = "Name is the name of the HTTP Header to be matched. Name matching MUST be\ncase-insensitive. (See https://tools.ietf.org/html/rfc7230#section-3.2).\n\nIf multiple entries specify equivalent header names, the first entry with\nan equivalent name MUST be considered for a match. Subsequent entries\nwith an equivalent header name MUST be ignored. Due to the\ncase-insensitivity of header names, \"foo\" and \"Foo\" are considered\nequivalent.";
            type = types.str;
          };
          "value" = mkOption {
            description = "Value is the value of HTTP Header to be matched.";
            type = types.str;
          };
        };

        config = { };

      };
    "gateway.networking.k8s.io.v1beta1.HTTPRouteSpecRulesBackendRefsFiltersResponseHeaderModifierSet" =
      {

        options = {
          "name" = mkOption {
            description = "Name is the name of the HTTP Header to be matched. Name matching MUST be\ncase-insensitive. (See https://tools.ietf.org/html/rfc7230#section-3.2).\n\nIf multiple entries specify equivalent header names, the first entry with\nan equivalent name MUST be considered for a match. Subsequent entries\nwith an equivalent header name MUST be ignored. Due to the\ncase-insensitivity of header names, \"foo\" and \"Foo\" are considered\nequivalent.";
            type = types.str;
          };
          "value" = mkOption {
            description = "Value is the value of HTTP Header to be matched.";
            type = types.str;
          };
        };

        config = { };

      };
    "gateway.networking.k8s.io.v1beta1.HTTPRouteSpecRulesBackendRefsFiltersUrlRewrite" = {

      options = {
        "hostname" = mkOption {
          description = "Hostname is the value to be used to replace the Host header value during\nforwarding.\n\nSupport: Extended";
          type = types.nullOr types.str;
        };
        "path" = mkOption {
          description = "Path defines a path rewrite.\n\nSupport: Extended";
          type = types.nullOr (
            submoduleOf "gateway.networking.k8s.io.v1beta1.HTTPRouteSpecRulesBackendRefsFiltersUrlRewritePath"
          );
        };
      };

      config = {
        "hostname" = mkOverride 1002 null;
        "path" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1beta1.HTTPRouteSpecRulesBackendRefsFiltersUrlRewritePath" = {

      options = {
        "replaceFullPath" = mkOption {
          description = "ReplaceFullPath specifies the value with which to replace the full path\nof a request during a rewrite or redirect.";
          type = types.nullOr types.str;
        };
        "replacePrefixMatch" = mkOption {
          description = "ReplacePrefixMatch specifies the value with which to replace the prefix\nmatch of a request during a rewrite or redirect. For example, a request\nto \"/foo/bar\" with a prefix match of \"/foo\" and a ReplacePrefixMatch\nof \"/xyz\" would be modified to \"/xyz/bar\".\n\nNote that this matches the behavior of the PathPrefix match type. This\nmatches full path elements. A path element refers to the list of labels\nin the path split by the `/` separator. When specified, a trailing `/` is\nignored. For example, the paths `/abc`, `/abc/`, and `/abc/def` would all\nmatch the prefix `/abc`, but the path `/abcd` would not.\n\nReplacePrefixMatch is only compatible with a `PathPrefix` HTTPRouteMatch.\nUsing any other HTTPRouteMatch type on the same HTTPRouteRule will result in\nthe implementation setting the Accepted Condition for the Route to `status: False`.\n\nRequest Path | Prefix Match | Replace Prefix | Modified Path";
          type = types.nullOr types.str;
        };
        "type" = mkOption {
          description = "Type defines the type of path modifier. Additional types may be\nadded in a future release of the API.\n\nNote that values may be added to this enum, implementations\nmust ensure that unknown values will not cause a crash.\n\nUnknown values here must result in the implementation setting the\nAccepted Condition for the Route to `status: False`, with a\nReason of `UnsupportedValue`.";
          type = types.str;
        };
      };

      config = {
        "replaceFullPath" = mkOverride 1002 null;
        "replacePrefixMatch" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1beta1.HTTPRouteSpecRulesFilters" = {

      options = {
        "extensionRef" = mkOption {
          description = "ExtensionRef is an optional, implementation-specific extension to the\n\"filter\" behavior.  For example, resource \"myroutefilter\" in group\n\"networking.example.net\"). ExtensionRef MUST NOT be used for core and\nextended filters.\n\nThis filter can be used multiple times within the same rule.\n\nSupport: Implementation-specific";
          type = types.nullOr (
            submoduleOf "gateway.networking.k8s.io.v1beta1.HTTPRouteSpecRulesFiltersExtensionRef"
          );
        };
        "requestHeaderModifier" = mkOption {
          description = "RequestHeaderModifier defines a schema for a filter that modifies request\nheaders.\n\nSupport: Core";
          type = types.nullOr (
            submoduleOf "gateway.networking.k8s.io.v1beta1.HTTPRouteSpecRulesFiltersRequestHeaderModifier"
          );
        };
        "requestMirror" = mkOption {
          description = "RequestMirror defines a schema for a filter that mirrors requests.\nRequests are sent to the specified destination, but responses from\nthat destination are ignored.\n\nThis filter can be used multiple times within the same rule. Note that\nnot all implementations will be able to support mirroring to multiple\nbackends.\n\nSupport: Extended";
          type = types.nullOr (
            submoduleOf "gateway.networking.k8s.io.v1beta1.HTTPRouteSpecRulesFiltersRequestMirror"
          );
        };
        "requestRedirect" = mkOption {
          description = "RequestRedirect defines a schema for a filter that responds to the\nrequest with an HTTP redirection.\n\nSupport: Core";
          type = types.nullOr (
            submoduleOf "gateway.networking.k8s.io.v1beta1.HTTPRouteSpecRulesFiltersRequestRedirect"
          );
        };
        "responseHeaderModifier" = mkOption {
          description = "ResponseHeaderModifier defines a schema for a filter that modifies response\nheaders.\n\nSupport: Extended";
          type = types.nullOr (
            submoduleOf "gateway.networking.k8s.io.v1beta1.HTTPRouteSpecRulesFiltersResponseHeaderModifier"
          );
        };
        "type" = mkOption {
          description = "Type identifies the type of filter to apply. As with other API fields,\ntypes are classified into three conformance levels:\n\n- Core: Filter types and their corresponding configuration defined by\n  \"Support: Core\" in this package, e.g. \"RequestHeaderModifier\". All\n  implementations must support core filters.\n\n- Extended: Filter types and their corresponding configuration defined by\n  \"Support: Extended\" in this package, e.g. \"RequestMirror\". Implementers\n  are encouraged to support extended filters.\n\n- Implementation-specific: Filters that are defined and supported by\n  specific vendors.\n  In the future, filters showing convergence in behavior across multiple\n  implementations will be considered for inclusion in extended or core\n  conformance levels. Filter-specific configuration for such filters\n  is specified using the ExtensionRef field. `Type` should be set to\n  \"ExtensionRef\" for custom filters.\n\nImplementers are encouraged to define custom implementation types to\nextend the core API with implementation-specific behavior.\n\nIf a reference to a custom filter type cannot be resolved, the filter\nMUST NOT be skipped. Instead, requests that would have been processed by\nthat filter MUST receive a HTTP error response.\n\nNote that values may be added to this enum, implementations\nmust ensure that unknown values will not cause a crash.\n\nUnknown values here must result in the implementation setting the\nAccepted Condition for the Route to `status: False`, with a\nReason of `UnsupportedValue`.";
          type = types.str;
        };
        "urlRewrite" = mkOption {
          description = "URLRewrite defines a schema for a filter that modifies a request during forwarding.\n\nSupport: Extended";
          type = types.nullOr (
            submoduleOf "gateway.networking.k8s.io.v1beta1.HTTPRouteSpecRulesFiltersUrlRewrite"
          );
        };
      };

      config = {
        "extensionRef" = mkOverride 1002 null;
        "requestHeaderModifier" = mkOverride 1002 null;
        "requestMirror" = mkOverride 1002 null;
        "requestRedirect" = mkOverride 1002 null;
        "responseHeaderModifier" = mkOverride 1002 null;
        "urlRewrite" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1beta1.HTTPRouteSpecRulesFiltersExtensionRef" = {

      options = {
        "group" = mkOption {
          description = "Group is the group of the referent. For example, \"gateway.networking.k8s.io\".\nWhen unspecified or empty string, core API group is inferred.";
          type = types.str;
        };
        "kind" = mkOption {
          description = "Kind is kind of the referent. For example \"HTTPRoute\" or \"Service\".";
          type = types.str;
        };
        "name" = mkOption {
          description = "Name is the name of the referent.";
          type = types.str;
        };
      };

      config = { };

    };
    "gateway.networking.k8s.io.v1beta1.HTTPRouteSpecRulesFiltersRequestHeaderModifier" = {

      options = {
        "add" = mkOption {
          description = "Add adds the given header(s) (name, value) to the request\nbefore the action. It appends to any existing values associated\nwith the header name.\n\nInput:\n  GET /foo HTTP/1.1\n  my-header: foo\n\nConfig:\n  add:\n  - name: \"my-header\"\n    value: \"bar,baz\"\n\nOutput:\n  GET /foo HTTP/1.1\n  my-header: foo,bar,baz";
          type = types.nullOr (
            coerceAttrsOfSubmodulesToListByKey
              "gateway.networking.k8s.io.v1beta1.HTTPRouteSpecRulesFiltersRequestHeaderModifierAdd"
              "name"
              [ "name" ]
          );
          apply = attrsToList;
        };
        "remove" = mkOption {
          description = "Remove the given header(s) from the HTTP request before the action. The\nvalue of Remove is a list of HTTP header names. Note that the header\nnames are case-insensitive (see\nhttps://datatracker.ietf.org/doc/html/rfc2616#section-4.2).\n\nInput:\n  GET /foo HTTP/1.1\n  my-header1: foo\n  my-header2: bar\n  my-header3: baz\n\nConfig:\n  remove: [\"my-header1\", \"my-header3\"]\n\nOutput:\n  GET /foo HTTP/1.1\n  my-header2: bar";
          type = types.nullOr (types.listOf types.str);
        };
        "set" = mkOption {
          description = "Set overwrites the request with the given header (name, value)\nbefore the action.\n\nInput:\n  GET /foo HTTP/1.1\n  my-header: foo\n\nConfig:\n  set:\n  - name: \"my-header\"\n    value: \"bar\"\n\nOutput:\n  GET /foo HTTP/1.1\n  my-header: bar";
          type = types.nullOr (
            coerceAttrsOfSubmodulesToListByKey
              "gateway.networking.k8s.io.v1beta1.HTTPRouteSpecRulesFiltersRequestHeaderModifierSet"
              "name"
              [ "name" ]
          );
          apply = attrsToList;
        };
      };

      config = {
        "add" = mkOverride 1002 null;
        "remove" = mkOverride 1002 null;
        "set" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1beta1.HTTPRouteSpecRulesFiltersRequestHeaderModifierAdd" = {

      options = {
        "name" = mkOption {
          description = "Name is the name of the HTTP Header to be matched. Name matching MUST be\ncase-insensitive. (See https://tools.ietf.org/html/rfc7230#section-3.2).\n\nIf multiple entries specify equivalent header names, the first entry with\nan equivalent name MUST be considered for a match. Subsequent entries\nwith an equivalent header name MUST be ignored. Due to the\ncase-insensitivity of header names, \"foo\" and \"Foo\" are considered\nequivalent.";
          type = types.str;
        };
        "value" = mkOption {
          description = "Value is the value of HTTP Header to be matched.";
          type = types.str;
        };
      };

      config = { };

    };
    "gateway.networking.k8s.io.v1beta1.HTTPRouteSpecRulesFiltersRequestHeaderModifierSet" = {

      options = {
        "name" = mkOption {
          description = "Name is the name of the HTTP Header to be matched. Name matching MUST be\ncase-insensitive. (See https://tools.ietf.org/html/rfc7230#section-3.2).\n\nIf multiple entries specify equivalent header names, the first entry with\nan equivalent name MUST be considered for a match. Subsequent entries\nwith an equivalent header name MUST be ignored. Due to the\ncase-insensitivity of header names, \"foo\" and \"Foo\" are considered\nequivalent.";
          type = types.str;
        };
        "value" = mkOption {
          description = "Value is the value of HTTP Header to be matched.";
          type = types.str;
        };
      };

      config = { };

    };
    "gateway.networking.k8s.io.v1beta1.HTTPRouteSpecRulesFiltersRequestMirror" = {

      options = {
        "backendRef" = mkOption {
          description = "BackendRef references a resource where mirrored requests are sent.\n\nMirrored requests must be sent only to a single destination endpoint\nwithin this BackendRef, irrespective of how many endpoints are present\nwithin this BackendRef.\n\nIf the referent cannot be found, this BackendRef is invalid and must be\ndropped from the Gateway. The controller must ensure the \"ResolvedRefs\"\ncondition on the Route status is set to `status: False` and not configure\nthis backend in the underlying implementation.\n\nIf there is a cross-namespace reference to an *existing* object\nthat is not allowed by a ReferenceGrant, the controller must ensure the\n\"ResolvedRefs\"  condition on the Route is set to `status: False`,\nwith the \"RefNotPermitted\" reason and not configure this backend in the\nunderlying implementation.\n\nIn either error case, the Message of the `ResolvedRefs` Condition\nshould be used to provide more detail about the problem.\n\nSupport: Extended for Kubernetes Service\n\nSupport: Implementation-specific for any other resource";
          type = submoduleOf "gateway.networking.k8s.io.v1beta1.HTTPRouteSpecRulesFiltersRequestMirrorBackendRef";
        };
        "fraction" = mkOption {
          description = "Fraction represents the fraction of requests that should be\nmirrored to BackendRef.\n\nOnly one of Fraction or Percent may be specified. If neither field\nis specified, 100% of requests will be mirrored.";
          type = types.nullOr (
            submoduleOf "gateway.networking.k8s.io.v1beta1.HTTPRouteSpecRulesFiltersRequestMirrorFraction"
          );
        };
        "percent" = mkOption {
          description = "Percent represents the percentage of requests that should be\nmirrored to BackendRef. Its minimum value is 0 (indicating 0% of\nrequests) and its maximum value is 100 (indicating 100% of requests).\n\nOnly one of Fraction or Percent may be specified. If neither field\nis specified, 100% of requests will be mirrored.";
          type = types.nullOr types.int;
        };
      };

      config = {
        "fraction" = mkOverride 1002 null;
        "percent" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1beta1.HTTPRouteSpecRulesFiltersRequestMirrorBackendRef" = {

      options = {
        "group" = mkOption {
          description = "Group is the group of the referent. For example, \"gateway.networking.k8s.io\".\nWhen unspecified or empty string, core API group is inferred.";
          type = types.nullOr types.str;
        };
        "kind" = mkOption {
          description = "Kind is the Kubernetes resource kind of the referent. For example\n\"Service\".\n\nDefaults to \"Service\" when not specified.\n\nExternalName services can refer to CNAME DNS records that may live\noutside of the cluster and as such are difficult to reason about in\nterms of conformance. They also may not be safe to forward to (see\nCVE-2021-25740 for more information). Implementations SHOULD NOT\nsupport ExternalName Services.\n\nSupport: Core (Services with a type other than ExternalName)\n\nSupport: Implementation-specific (Services with type ExternalName)";
          type = types.nullOr types.str;
        };
        "name" = mkOption {
          description = "Name is the name of the referent.";
          type = types.str;
        };
        "namespace" = mkOption {
          description = "Namespace is the namespace of the backend. When unspecified, the local\nnamespace is inferred.\n\nNote that when a namespace different than the local namespace is specified,\na ReferenceGrant object is required in the referent namespace to allow that\nnamespace's owner to accept the reference. See the ReferenceGrant\ndocumentation for details.\n\nSupport: Core";
          type = types.nullOr types.str;
        };
        "port" = mkOption {
          description = "Port specifies the destination port number to use for this resource.\nPort is required when the referent is a Kubernetes Service. In this\ncase, the port number is the service port number, not the target port.\nFor other resources, destination port might be derived from the referent\nresource or this field.";
          type = types.nullOr types.int;
        };
      };

      config = {
        "group" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
        "port" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1beta1.HTTPRouteSpecRulesFiltersRequestMirrorFraction" = {

      options = {
        "denominator" = mkOption {
          description = "";
          type = types.nullOr types.int;
        };
        "numerator" = mkOption {
          description = "";
          type = types.int;
        };
      };

      config = {
        "denominator" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1beta1.HTTPRouteSpecRulesFiltersRequestRedirect" = {

      options = {
        "hostname" = mkOption {
          description = "Hostname is the hostname to be used in the value of the `Location`\nheader in the response.\nWhen empty, the hostname in the `Host` header of the request is used.\n\nSupport: Core";
          type = types.nullOr types.str;
        };
        "path" = mkOption {
          description = "Path defines parameters used to modify the path of the incoming request.\nThe modified path is then used to construct the `Location` header. When\nempty, the request path is used as-is.\n\nSupport: Extended";
          type = types.nullOr (
            submoduleOf "gateway.networking.k8s.io.v1beta1.HTTPRouteSpecRulesFiltersRequestRedirectPath"
          );
        };
        "port" = mkOption {
          description = "Port is the port to be used in the value of the `Location`\nheader in the response.\n\nIf no port is specified, the redirect port MUST be derived using the\nfollowing rules:\n\n* If redirect scheme is not-empty, the redirect port MUST be the well-known\n  port associated with the redirect scheme. Specifically \"http\" to port 80\n  and \"https\" to port 443. If the redirect scheme does not have a\n  well-known port, the listener port of the Gateway SHOULD be used.\n* If redirect scheme is empty, the redirect port MUST be the Gateway\n  Listener port.\n\nImplementations SHOULD NOT add the port number in the 'Location'\nheader in the following cases:\n\n* A Location header that will use HTTP (whether that is determined via\n  the Listener protocol or the Scheme field) _and_ use port 80.\n* A Location header that will use HTTPS (whether that is determined via\n  the Listener protocol or the Scheme field) _and_ use port 443.\n\nSupport: Extended";
          type = types.nullOr types.int;
        };
        "scheme" = mkOption {
          description = "Scheme is the scheme to be used in the value of the `Location` header in\nthe response. When empty, the scheme of the request is used.\n\nScheme redirects can affect the port of the redirect, for more information,\nrefer to the documentation for the port field of this filter.\n\nNote that values may be added to this enum, implementations\nmust ensure that unknown values will not cause a crash.\n\nUnknown values here must result in the implementation setting the\nAccepted Condition for the Route to `status: False`, with a\nReason of `UnsupportedValue`.\n\nSupport: Extended";
          type = types.nullOr types.str;
        };
        "statusCode" = mkOption {
          description = "StatusCode is the HTTP status code to be used in response.\n\nNote that values may be added to this enum, implementations\nmust ensure that unknown values will not cause a crash.\n\nUnknown values here must result in the implementation setting the\nAccepted Condition for the Route to `status: False`, with a\nReason of `UnsupportedValue`.\n\nSupport: Core";
          type = types.nullOr types.int;
        };
      };

      config = {
        "hostname" = mkOverride 1002 null;
        "path" = mkOverride 1002 null;
        "port" = mkOverride 1002 null;
        "scheme" = mkOverride 1002 null;
        "statusCode" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1beta1.HTTPRouteSpecRulesFiltersRequestRedirectPath" = {

      options = {
        "replaceFullPath" = mkOption {
          description = "ReplaceFullPath specifies the value with which to replace the full path\nof a request during a rewrite or redirect.";
          type = types.nullOr types.str;
        };
        "replacePrefixMatch" = mkOption {
          description = "ReplacePrefixMatch specifies the value with which to replace the prefix\nmatch of a request during a rewrite or redirect. For example, a request\nto \"/foo/bar\" with a prefix match of \"/foo\" and a ReplacePrefixMatch\nof \"/xyz\" would be modified to \"/xyz/bar\".\n\nNote that this matches the behavior of the PathPrefix match type. This\nmatches full path elements. A path element refers to the list of labels\nin the path split by the `/` separator. When specified, a trailing `/` is\nignored. For example, the paths `/abc`, `/abc/`, and `/abc/def` would all\nmatch the prefix `/abc`, but the path `/abcd` would not.\n\nReplacePrefixMatch is only compatible with a `PathPrefix` HTTPRouteMatch.\nUsing any other HTTPRouteMatch type on the same HTTPRouteRule will result in\nthe implementation setting the Accepted Condition for the Route to `status: False`.\n\nRequest Path | Prefix Match | Replace Prefix | Modified Path";
          type = types.nullOr types.str;
        };
        "type" = mkOption {
          description = "Type defines the type of path modifier. Additional types may be\nadded in a future release of the API.\n\nNote that values may be added to this enum, implementations\nmust ensure that unknown values will not cause a crash.\n\nUnknown values here must result in the implementation setting the\nAccepted Condition for the Route to `status: False`, with a\nReason of `UnsupportedValue`.";
          type = types.str;
        };
      };

      config = {
        "replaceFullPath" = mkOverride 1002 null;
        "replacePrefixMatch" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1beta1.HTTPRouteSpecRulesFiltersResponseHeaderModifier" = {

      options = {
        "add" = mkOption {
          description = "Add adds the given header(s) (name, value) to the request\nbefore the action. It appends to any existing values associated\nwith the header name.\n\nInput:\n  GET /foo HTTP/1.1\n  my-header: foo\n\nConfig:\n  add:\n  - name: \"my-header\"\n    value: \"bar,baz\"\n\nOutput:\n  GET /foo HTTP/1.1\n  my-header: foo,bar,baz";
          type = types.nullOr (
            coerceAttrsOfSubmodulesToListByKey
              "gateway.networking.k8s.io.v1beta1.HTTPRouteSpecRulesFiltersResponseHeaderModifierAdd"
              "name"
              [ "name" ]
          );
          apply = attrsToList;
        };
        "remove" = mkOption {
          description = "Remove the given header(s) from the HTTP request before the action. The\nvalue of Remove is a list of HTTP header names. Note that the header\nnames are case-insensitive (see\nhttps://datatracker.ietf.org/doc/html/rfc2616#section-4.2).\n\nInput:\n  GET /foo HTTP/1.1\n  my-header1: foo\n  my-header2: bar\n  my-header3: baz\n\nConfig:\n  remove: [\"my-header1\", \"my-header3\"]\n\nOutput:\n  GET /foo HTTP/1.1\n  my-header2: bar";
          type = types.nullOr (types.listOf types.str);
        };
        "set" = mkOption {
          description = "Set overwrites the request with the given header (name, value)\nbefore the action.\n\nInput:\n  GET /foo HTTP/1.1\n  my-header: foo\n\nConfig:\n  set:\n  - name: \"my-header\"\n    value: \"bar\"\n\nOutput:\n  GET /foo HTTP/1.1\n  my-header: bar";
          type = types.nullOr (
            coerceAttrsOfSubmodulesToListByKey
              "gateway.networking.k8s.io.v1beta1.HTTPRouteSpecRulesFiltersResponseHeaderModifierSet"
              "name"
              [ "name" ]
          );
          apply = attrsToList;
        };
      };

      config = {
        "add" = mkOverride 1002 null;
        "remove" = mkOverride 1002 null;
        "set" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1beta1.HTTPRouteSpecRulesFiltersResponseHeaderModifierAdd" = {

      options = {
        "name" = mkOption {
          description = "Name is the name of the HTTP Header to be matched. Name matching MUST be\ncase-insensitive. (See https://tools.ietf.org/html/rfc7230#section-3.2).\n\nIf multiple entries specify equivalent header names, the first entry with\nan equivalent name MUST be considered for a match. Subsequent entries\nwith an equivalent header name MUST be ignored. Due to the\ncase-insensitivity of header names, \"foo\" and \"Foo\" are considered\nequivalent.";
          type = types.str;
        };
        "value" = mkOption {
          description = "Value is the value of HTTP Header to be matched.";
          type = types.str;
        };
      };

      config = { };

    };
    "gateway.networking.k8s.io.v1beta1.HTTPRouteSpecRulesFiltersResponseHeaderModifierSet" = {

      options = {
        "name" = mkOption {
          description = "Name is the name of the HTTP Header to be matched. Name matching MUST be\ncase-insensitive. (See https://tools.ietf.org/html/rfc7230#section-3.2).\n\nIf multiple entries specify equivalent header names, the first entry with\nan equivalent name MUST be considered for a match. Subsequent entries\nwith an equivalent header name MUST be ignored. Due to the\ncase-insensitivity of header names, \"foo\" and \"Foo\" are considered\nequivalent.";
          type = types.str;
        };
        "value" = mkOption {
          description = "Value is the value of HTTP Header to be matched.";
          type = types.str;
        };
      };

      config = { };

    };
    "gateway.networking.k8s.io.v1beta1.HTTPRouteSpecRulesFiltersUrlRewrite" = {

      options = {
        "hostname" = mkOption {
          description = "Hostname is the value to be used to replace the Host header value during\nforwarding.\n\nSupport: Extended";
          type = types.nullOr types.str;
        };
        "path" = mkOption {
          description = "Path defines a path rewrite.\n\nSupport: Extended";
          type = types.nullOr (
            submoduleOf "gateway.networking.k8s.io.v1beta1.HTTPRouteSpecRulesFiltersUrlRewritePath"
          );
        };
      };

      config = {
        "hostname" = mkOverride 1002 null;
        "path" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1beta1.HTTPRouteSpecRulesFiltersUrlRewritePath" = {

      options = {
        "replaceFullPath" = mkOption {
          description = "ReplaceFullPath specifies the value with which to replace the full path\nof a request during a rewrite or redirect.";
          type = types.nullOr types.str;
        };
        "replacePrefixMatch" = mkOption {
          description = "ReplacePrefixMatch specifies the value with which to replace the prefix\nmatch of a request during a rewrite or redirect. For example, a request\nto \"/foo/bar\" with a prefix match of \"/foo\" and a ReplacePrefixMatch\nof \"/xyz\" would be modified to \"/xyz/bar\".\n\nNote that this matches the behavior of the PathPrefix match type. This\nmatches full path elements. A path element refers to the list of labels\nin the path split by the `/` separator. When specified, a trailing `/` is\nignored. For example, the paths `/abc`, `/abc/`, and `/abc/def` would all\nmatch the prefix `/abc`, but the path `/abcd` would not.\n\nReplacePrefixMatch is only compatible with a `PathPrefix` HTTPRouteMatch.\nUsing any other HTTPRouteMatch type on the same HTTPRouteRule will result in\nthe implementation setting the Accepted Condition for the Route to `status: False`.\n\nRequest Path | Prefix Match | Replace Prefix | Modified Path";
          type = types.nullOr types.str;
        };
        "type" = mkOption {
          description = "Type defines the type of path modifier. Additional types may be\nadded in a future release of the API.\n\nNote that values may be added to this enum, implementations\nmust ensure that unknown values will not cause a crash.\n\nUnknown values here must result in the implementation setting the\nAccepted Condition for the Route to `status: False`, with a\nReason of `UnsupportedValue`.";
          type = types.str;
        };
      };

      config = {
        "replaceFullPath" = mkOverride 1002 null;
        "replacePrefixMatch" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1beta1.HTTPRouteSpecRulesMatches" = {

      options = {
        "headers" = mkOption {
          description = "Headers specifies HTTP request header matchers. Multiple match values are\nANDed together, meaning, a request must match all the specified headers\nto select the route.";
          type = types.nullOr (
            coerceAttrsOfSubmodulesToListByKey
              "gateway.networking.k8s.io.v1beta1.HTTPRouteSpecRulesMatchesHeaders"
              "name"
              [ "name" ]
          );
          apply = attrsToList;
        };
        "method" = mkOption {
          description = "Method specifies HTTP method matcher.\nWhen specified, this route will be matched only if the request has the\nspecified method.\n\nSupport: Extended";
          type = types.nullOr types.str;
        };
        "path" = mkOption {
          description = "Path specifies a HTTP request path matcher. If this field is not\nspecified, a default prefix match on the \"/\" path is provided.";
          type = types.nullOr (submoduleOf "gateway.networking.k8s.io.v1beta1.HTTPRouteSpecRulesMatchesPath");
        };
        "queryParams" = mkOption {
          description = "QueryParams specifies HTTP query parameter matchers. Multiple match\nvalues are ANDed together, meaning, a request must match all the\nspecified query parameters to select the route.\n\nSupport: Extended";
          type = types.nullOr (
            coerceAttrsOfSubmodulesToListByKey
              "gateway.networking.k8s.io.v1beta1.HTTPRouteSpecRulesMatchesQueryParams"
              "name"
              [ "name" ]
          );
          apply = attrsToList;
        };
      };

      config = {
        "headers" = mkOverride 1002 null;
        "method" = mkOverride 1002 null;
        "path" = mkOverride 1002 null;
        "queryParams" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1beta1.HTTPRouteSpecRulesMatchesHeaders" = {

      options = {
        "name" = mkOption {
          description = "Name is the name of the HTTP Header to be matched. Name matching MUST be\ncase-insensitive. (See https://tools.ietf.org/html/rfc7230#section-3.2).\n\nIf multiple entries specify equivalent header names, only the first\nentry with an equivalent name MUST be considered for a match. Subsequent\nentries with an equivalent header name MUST be ignored. Due to the\ncase-insensitivity of header names, \"foo\" and \"Foo\" are considered\nequivalent.\n\nWhen a header is repeated in an HTTP request, it is\nimplementation-specific behavior as to how this is represented.\nGenerally, proxies should follow the guidance from the RFC:\nhttps://www.rfc-editor.org/rfc/rfc7230.html#section-3.2.2 regarding\nprocessing a repeated header, with special handling for \"Set-Cookie\".";
          type = types.str;
        };
        "type" = mkOption {
          description = "Type specifies how to match against the value of the header.\n\nSupport: Core (Exact)\n\nSupport: Implementation-specific (RegularExpression)\n\nSince RegularExpression HeaderMatchType has implementation-specific\nconformance, implementations can support POSIX, PCRE or any other dialects\nof regular expressions. Please read the implementation's documentation to\ndetermine the supported dialect.";
          type = types.nullOr types.str;
        };
        "value" = mkOption {
          description = "Value is the value of HTTP Header to be matched.";
          type = types.str;
        };
      };

      config = {
        "type" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1beta1.HTTPRouteSpecRulesMatchesPath" = {

      options = {
        "type" = mkOption {
          description = "Type specifies how to match against the path Value.\n\nSupport: Core (Exact, PathPrefix)\n\nSupport: Implementation-specific (RegularExpression)";
          type = types.nullOr types.str;
        };
        "value" = mkOption {
          description = "Value of the HTTP path to match against.";
          type = types.nullOr types.str;
        };
      };

      config = {
        "type" = mkOverride 1002 null;
        "value" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1beta1.HTTPRouteSpecRulesMatchesQueryParams" = {

      options = {
        "name" = mkOption {
          description = "Name is the name of the HTTP query param to be matched. This must be an\nexact string match. (See\nhttps://tools.ietf.org/html/rfc7230#section-2.7.3).\n\nIf multiple entries specify equivalent query param names, only the first\nentry with an equivalent name MUST be considered for a match. Subsequent\nentries with an equivalent query param name MUST be ignored.\n\nIf a query param is repeated in an HTTP request, the behavior is\npurposely left undefined, since different data planes have different\ncapabilities. However, it is *recommended* that implementations should\nmatch against the first value of the param if the data plane supports it,\nas this behavior is expected in other load balancing contexts outside of\nthe Gateway API.\n\nUsers SHOULD NOT route traffic based on repeated query params to guard\nthemselves against potential differences in the implementations.";
          type = types.str;
        };
        "type" = mkOption {
          description = "Type specifies how to match against the value of the query parameter.\n\nSupport: Extended (Exact)\n\nSupport: Implementation-specific (RegularExpression)\n\nSince RegularExpression QueryParamMatchType has Implementation-specific\nconformance, implementations can support POSIX, PCRE or any other\ndialects of regular expressions. Please read the implementation's\ndocumentation to determine the supported dialect.";
          type = types.nullOr types.str;
        };
        "value" = mkOption {
          description = "Value is the value of HTTP query param to be matched.";
          type = types.str;
        };
      };

      config = {
        "type" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1beta1.HTTPRouteSpecRulesTimeouts" = {

      options = {
        "backendRequest" = mkOption {
          description = "BackendRequest specifies a timeout for an individual request from the gateway\nto a backend. This covers the time from when the request first starts being\nsent from the gateway to when the full response has been received from the backend.\n\nSetting a timeout to the zero duration (e.g. \"0s\") SHOULD disable the timeout\ncompletely. Implementations that cannot completely disable the timeout MUST\ninstead interpret the zero duration as the longest possible value to which\nthe timeout can be set.\n\nAn entire client HTTP transaction with a gateway, covered by the Request timeout,\nmay result in more than one call from the gateway to the destination backend,\nfor example, if automatic retries are supported.\n\nThe value of BackendRequest must be a Gateway API Duration string as defined by\nGEP-2257.  When this field is unspecified, its behavior is implementation-specific;\nwhen specified, the value of BackendRequest must be no more than the value of the\nRequest timeout (since the Request timeout encompasses the BackendRequest timeout).\n\nSupport: Extended";
          type = types.nullOr types.str;
        };
        "request" = mkOption {
          description = "Request specifies the maximum duration for a gateway to respond to an HTTP request.\nIf the gateway has not been able to respond before this deadline is met, the gateway\nMUST return a timeout error.\n\nFor example, setting the `rules.timeouts.request` field to the value `10s` in an\n`HTTPRoute` will cause a timeout if a client request is taking longer than 10 seconds\nto complete.\n\nSetting a timeout to the zero duration (e.g. \"0s\") SHOULD disable the timeout\ncompletely. Implementations that cannot completely disable the timeout MUST\ninstead interpret the zero duration as the longest possible value to which\nthe timeout can be set.\n\nThis timeout is intended to cover as close to the whole request-response transaction\nas possible although an implementation MAY choose to start the timeout after the entire\nrequest stream has been received instead of immediately after the transaction is\ninitiated by the client.\n\nThe value of Request is a Gateway API Duration string as defined by GEP-2257. When this\nfield is unspecified, request timeout behavior is implementation-specific.\n\nSupport: Extended";
          type = types.nullOr types.str;
        };
      };

      config = {
        "backendRequest" = mkOverride 1002 null;
        "request" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1beta1.HTTPRouteStatus" = {

      options = {
        "parents" = mkOption {
          description = "Parents is a list of parent resources (usually Gateways) that are\nassociated with the route, and the status of the route with respect to\neach parent. When this route attaches to a parent, the controller that\nmanages the parent must add an entry to this list when the controller\nfirst sees the route and should update the entry as appropriate when the\nroute or gateway is modified.\n\nNote that parent references that cannot be resolved by an implementation\nof this API will not be added to this list. Implementations of this API\ncan only populate Route status for the Gateways/parent resources they are\nresponsible for.\n\nA maximum of 32 Gateways will be represented in this list. An empty list\nmeans the route has not been attached to any Gateway.";
          type = types.listOf (submoduleOf "gateway.networking.k8s.io.v1beta1.HTTPRouteStatusParents");
        };
      };

      config = { };

    };
    "gateway.networking.k8s.io.v1beta1.HTTPRouteStatusParents" = {

      options = {
        "conditions" = mkOption {
          description = "Conditions describes the status of the route with respect to the Gateway.\nNote that the route's availability is also subject to the Gateway's own\nstatus conditions and listener status.\n\nIf the Route's ParentRef specifies an existing Gateway that supports\nRoutes of this kind AND that Gateway's controller has sufficient access,\nthen that Gateway's controller MUST set the \"Accepted\" condition on the\nRoute, to indicate whether the route has been accepted or rejected by the\nGateway, and why.\n\nA Route MUST be considered \"Accepted\" if at least one of the Route's\nrules is implemented by the Gateway.\n\nThere are a number of cases where the \"Accepted\" condition may not be set\ndue to lack of controller visibility, that includes when:\n\n* The Route refers to a nonexistent parent.\n* The Route is of a type that the controller does not support.\n* The Route is in a namespace the controller does not have access to.";
          type = types.listOf (
            submoduleOf "gateway.networking.k8s.io.v1beta1.HTTPRouteStatusParentsConditions"
          );
        };
        "controllerName" = mkOption {
          description = "ControllerName is a domain/path string that indicates the name of the\ncontroller that wrote this status. This corresponds with the\ncontrollerName field on GatewayClass.\n\nExample: \"example.net/gateway-controller\".\n\nThe format of this field is DOMAIN \"/\" PATH, where DOMAIN and PATH are\nvalid Kubernetes names\n(https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names).\n\nControllers MUST populate this field when writing status. Controllers should ensure that\nentries to status populated with their ControllerName are cleaned up when they are no\nlonger necessary.";
          type = types.str;
        };
        "parentRef" = mkOption {
          description = "ParentRef corresponds with a ParentRef in the spec that this\nRouteParentStatus struct describes the status of.";
          type = submoduleOf "gateway.networking.k8s.io.v1beta1.HTTPRouteStatusParentsParentRef";
        };
      };

      config = { };

    };
    "gateway.networking.k8s.io.v1beta1.HTTPRouteStatusParentsConditions" = {

      options = {
        "lastTransitionTime" = mkOption {
          description = "lastTransitionTime is the last time the condition transitioned from one status to another.\nThis should be when the underlying condition changed.  If that is not known, then using the time when the API field changed is acceptable.";
          type = types.str;
        };
        "message" = mkOption {
          description = "message is a human readable message indicating details about the transition.\nThis may be an empty string.";
          type = types.str;
        };
        "observedGeneration" = mkOption {
          description = "observedGeneration represents the .metadata.generation that the condition was set based upon.\nFor instance, if .metadata.generation is currently 12, but the .status.conditions[x].observedGeneration is 9, the condition is out of date\nwith respect to the current state of the instance.";
          type = types.nullOr types.int;
        };
        "reason" = mkOption {
          description = "reason contains a programmatic identifier indicating the reason for the condition's last transition.\nProducers of specific condition types may define expected values and meanings for this field,\nand whether the values are considered a guaranteed API.\nThe value should be a CamelCase string.\nThis field may not be empty.";
          type = types.str;
        };
        "status" = mkOption {
          description = "status of the condition, one of True, False, Unknown.";
          type = types.str;
        };
        "type" = mkOption {
          description = "type of condition in CamelCase or in foo.example.com/CamelCase.";
          type = types.str;
        };
      };

      config = {
        "observedGeneration" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1beta1.HTTPRouteStatusParentsParentRef" = {

      options = {
        "group" = mkOption {
          description = "Group is the group of the referent.\nWhen unspecified, \"gateway.networking.k8s.io\" is inferred.\nTo set the core API group (such as for a \"Service\" kind referent),\nGroup must be explicitly set to \"\" (empty string).\n\nSupport: Core";
          type = types.nullOr types.str;
        };
        "kind" = mkOption {
          description = "Kind is kind of the referent.\n\nThere are two kinds of parent resources with \"Core\" support:\n\n* Gateway (Gateway conformance profile)\n* Service (Mesh conformance profile, ClusterIP Services only)\n\nSupport for other resources is Implementation-Specific.";
          type = types.nullOr types.str;
        };
        "name" = mkOption {
          description = "Name is the name of the referent.\n\nSupport: Core";
          type = types.str;
        };
        "namespace" = mkOption {
          description = "Namespace is the namespace of the referent. When unspecified, this refers\nto the local namespace of the Route.\n\nNote that there are specific rules for ParentRefs which cross namespace\nboundaries. Cross-namespace references are only valid if they are explicitly\nallowed by something in the namespace they are referring to. For example:\nGateway has the AllowedRoutes field, and ReferenceGrant provides a\ngeneric way to enable any other kind of cross-namespace reference.\n\nSupport: Core";
          type = types.nullOr types.str;
        };
        "port" = mkOption {
          description = "Port is the network port this Route targets. It can be interpreted\ndifferently based on the type of parent resource.\n\nWhen the parent resource is a Gateway, this targets all listeners\nlistening on the specified port that also support this kind of Route(and\nselect this Route). It's not recommended to set `Port` unless the\nnetworking behaviors specified in a Route must apply to a specific port\nas opposed to a listener(s) whose port(s) may be changed. When both Port\nand SectionName are specified, the name and port of the selected listener\nmust match both specified values.\n\nImplementations MAY choose to support other parent resources.\nImplementations supporting other types of parent resources MUST clearly\ndocument how/if Port is interpreted.\n\nFor the purpose of status, an attachment is considered successful as\nlong as the parent resource accepts it partially. For example, Gateway\nlisteners can restrict which Routes can attach to them by Route kind,\nnamespace, or hostname. If 1 of 2 Gateway listeners accept attachment\nfrom the referencing Route, the Route MUST be considered successfully\nattached. If no Gateway listeners accept attachment from this Route,\nthe Route MUST be considered detached from the Gateway.\n\nSupport: Extended";
          type = types.nullOr types.int;
        };
        "sectionName" = mkOption {
          description = "SectionName is the name of a section within the target resource. In the\nfollowing resources, SectionName is interpreted as the following:\n\n* Gateway: Listener name. When both Port (experimental) and SectionName\nare specified, the name and port of the selected listener must match\nboth specified values.\n* Service: Port name. When both Port (experimental) and SectionName\nare specified, the name and port of the selected listener must match\nboth specified values.\n\nImplementations MAY choose to support attaching Routes to other resources.\nIf that is the case, they MUST clearly document how SectionName is\ninterpreted.\n\nWhen unspecified (empty string), this will reference the entire resource.\nFor the purpose of status, an attachment is considered successful if at\nleast one section in the parent resource accepts it. For example, Gateway\nlisteners can restrict which Routes can attach to them by Route kind,\nnamespace, or hostname. If 1 of 2 Gateway listeners accept attachment from\nthe referencing Route, the Route MUST be considered successfully\nattached. If no Gateway listeners accept attachment from this Route, the\nRoute MUST be considered detached from the Gateway.\n\nSupport: Core";
          type = types.nullOr types.str;
        };
      };

      config = {
        "group" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
        "port" = mkOverride 1002 null;
        "sectionName" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1beta1.ReferenceGrant" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object.\nServers should convert recognized schemas to the latest internal value, and\nmay reject unrecognized values.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = types.nullOr types.str;
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents.\nServers may infer this from the endpoint the client submits requests to.\nCannot be updated.\nIn CamelCase.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = types.nullOr types.str;
        };
        "metadata" = mkOption {
          description = "Standard object's metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = types.nullOr (globalSubmoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta");
        };
        "spec" = mkOption {
          description = "Spec defines the desired state of ReferenceGrant.";
          type = types.nullOr (submoduleOf "gateway.networking.k8s.io.v1beta1.ReferenceGrantSpec");
        };
      };

      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "spec" = mkOverride 1002 null;
      };

    };
    "gateway.networking.k8s.io.v1beta1.ReferenceGrantSpec" = {

      options = {
        "from" = mkOption {
          description = "From describes the trusted namespaces and kinds that can reference the\nresources described in \"To\". Each entry in this list MUST be considered\nto be an additional place that references can be valid from, or to put\nthis another way, entries MUST be combined using OR.\n\nSupport: Core";
          type = types.listOf (submoduleOf "gateway.networking.k8s.io.v1beta1.ReferenceGrantSpecFrom");
        };
        "to" = mkOption {
          description = "To describes the resources that may be referenced by the resources\ndescribed in \"From\". Each entry in this list MUST be considered to be an\nadditional place that references can be valid to, or to put this another\nway, entries MUST be combined using OR.\n\nSupport: Core";
          type =
            coerceAttrsOfSubmodulesToListByKey "gateway.networking.k8s.io.v1beta1.ReferenceGrantSpecTo" "name"
              [ ];
          apply = attrsToList;
        };
      };

      config = { };

    };
    "gateway.networking.k8s.io.v1beta1.ReferenceGrantSpecFrom" = {

      options = {
        "group" = mkOption {
          description = "Group is the group of the referent.\nWhen empty, the Kubernetes core API group is inferred.\n\nSupport: Core";
          type = types.str;
        };
        "kind" = mkOption {
          description = "Kind is the kind of the referent. Although implementations may support\nadditional resources, the following types are part of the \"Core\"\nsupport level for this field.\n\nWhen used to permit a SecretObjectReference:\n\n* Gateway\n\nWhen used to permit a BackendObjectReference:\n\n* GRPCRoute\n* HTTPRoute\n* TCPRoute\n* TLSRoute\n* UDPRoute";
          type = types.str;
        };
        "namespace" = mkOption {
          description = "Namespace is the namespace of the referent.\n\nSupport: Core";
          type = types.str;
        };
      };

      config = { };

    };
    "gateway.networking.k8s.io.v1beta1.ReferenceGrantSpecTo" = {

      options = {
        "group" = mkOption {
          description = "Group is the group of the referent.\nWhen empty, the Kubernetes core API group is inferred.\n\nSupport: Core";
          type = types.str;
        };
        "kind" = mkOption {
          description = "Kind is the kind of the referent. Although implementations may support\nadditional resources, the following types are part of the \"Core\"\nsupport level for this field:\n\n* Secret when used to permit a SecretObjectReference\n* Service when used to permit a BackendObjectReference";
          type = types.str;
        };
        "name" = mkOption {
          description = "Name is the name of the referent. When unspecified, this policy\nrefers to all resources of the specified Group and Kind in the local\nnamespace.";
          type = types.nullOr types.str;
        };
      };

      config = {
        "name" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.AIService" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object.\nServers should convert recognized schemas to the latest internal value, and\nmay reject unrecognized values.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = types.nullOr types.str;
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents.\nServers may infer this from the endpoint the client submits requests to.\nCannot be updated.\nIn CamelCase.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = types.nullOr types.str;
        };
        "metadata" = mkOption {
          description = "Standard object's metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = types.nullOr (globalSubmoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta");
        };
        "spec" = mkOption {
          description = "The desired behavior of this AIService.";
          type = types.nullOr (submoduleOf "hub.traefik.io.v1alpha1.AIServiceSpec");
        };
      };

      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "spec" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.AIServiceSpec" = {

      options = {
        "anthropic" = mkOption {
          description = "Anthropic configures Anthropic backend.";
          type = types.nullOr (submoduleOf "hub.traefik.io.v1alpha1.AIServiceSpecAnthropic");
        };
        "azureOpenai" = mkOption {
          description = "AzureOpenAI configures AzureOpenAI.";
          type = types.nullOr (submoduleOf "hub.traefik.io.v1alpha1.AIServiceSpecAzureOpenai");
        };
        "bedrock" = mkOption {
          description = "Bedrock configures Bedrock backend.";
          type = types.nullOr (submoduleOf "hub.traefik.io.v1alpha1.AIServiceSpecBedrock");
        };
        "cohere" = mkOption {
          description = "Cohere configures Cohere backend.";
          type = types.nullOr (submoduleOf "hub.traefik.io.v1alpha1.AIServiceSpecCohere");
        };
        "deepSeek" = mkOption {
          description = "DeepSeek configures DeepSeek.";
          type = types.nullOr (submoduleOf "hub.traefik.io.v1alpha1.AIServiceSpecDeepSeek");
        };
        "gemini" = mkOption {
          description = "Gemini configures Gemini backend.";
          type = types.nullOr (submoduleOf "hub.traefik.io.v1alpha1.AIServiceSpecGemini");
        };
        "mistral" = mkOption {
          description = "Mistral configures Mistral AI backend.";
          type = types.nullOr (submoduleOf "hub.traefik.io.v1alpha1.AIServiceSpecMistral");
        };
        "ollama" = mkOption {
          description = "Ollama configures Ollama backend.";
          type = types.nullOr (submoduleOf "hub.traefik.io.v1alpha1.AIServiceSpecOllama");
        };
        "openai" = mkOption {
          description = "OpenAI configures OpenAI.";
          type = types.nullOr (submoduleOf "hub.traefik.io.v1alpha1.AIServiceSpecOpenai");
        };
        "qWen" = mkOption {
          description = "QWen configures QWen.";
          type = types.nullOr (submoduleOf "hub.traefik.io.v1alpha1.AIServiceSpecQWen");
        };
      };

      config = {
        "anthropic" = mkOverride 1002 null;
        "azureOpenai" = mkOverride 1002 null;
        "bedrock" = mkOverride 1002 null;
        "cohere" = mkOverride 1002 null;
        "deepSeek" = mkOverride 1002 null;
        "gemini" = mkOverride 1002 null;
        "mistral" = mkOverride 1002 null;
        "ollama" = mkOverride 1002 null;
        "openai" = mkOverride 1002 null;
        "qWen" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.AIServiceSpecAnthropic" = {

      options = {
        "model" = mkOption {
          description = "";
          type = types.nullOr types.str;
        };
        "params" = mkOption {
          description = "Params holds the LLM hyperparameters.";
          type = types.nullOr (submoduleOf "hub.traefik.io.v1alpha1.AIServiceSpecAnthropicParams");
        };
        "token" = mkOption {
          description = "SecretReference references a kubernetes secret.";
          type = types.nullOr (submoduleOf "hub.traefik.io.v1alpha1.AIServiceSpecAnthropicToken");
        };
      };

      config = {
        "model" = mkOverride 1002 null;
        "params" = mkOverride 1002 null;
        "token" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.AIServiceSpecAnthropicParams" = {

      options = {
        "frequencyPenalty" = mkOption {
          description = "";
          type = types.nullOr (types.either types.int types.float);
        };
        "maxTokens" = mkOption {
          description = "";
          type = types.nullOr types.int;
        };
        "presencePenalty" = mkOption {
          description = "";
          type = types.nullOr (types.either types.int types.float);
        };
        "temperature" = mkOption {
          description = "";
          type = types.nullOr (types.either types.int types.float);
        };
        "topP" = mkOption {
          description = "";
          type = types.nullOr (types.either types.int types.float);
        };
      };

      config = {
        "frequencyPenalty" = mkOverride 1002 null;
        "maxTokens" = mkOverride 1002 null;
        "presencePenalty" = mkOverride 1002 null;
        "temperature" = mkOverride 1002 null;
        "topP" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.AIServiceSpecAnthropicToken" = {

      options = {
        "secretName" = mkOption {
          description = "";
          type = types.str;
        };
      };

      config = { };

    };
    "hub.traefik.io.v1alpha1.AIServiceSpecAzureOpenai" = {

      options = {
        "apiKeySecret" = mkOption {
          description = "SecretReference references a kubernetes secret.";
          type = types.nullOr (submoduleOf "hub.traefik.io.v1alpha1.AIServiceSpecAzureOpenaiApiKeySecret");
        };
        "baseUrl" = mkOption {
          description = "";
          type = types.str;
        };
        "deploymentName" = mkOption {
          description = "";
          type = types.str;
        };
        "model" = mkOption {
          description = "";
          type = types.nullOr types.str;
        };
        "params" = mkOption {
          description = "Params holds the LLM hyperparameters.";
          type = types.nullOr (submoduleOf "hub.traefik.io.v1alpha1.AIServiceSpecAzureOpenaiParams");
        };
      };

      config = {
        "apiKeySecret" = mkOverride 1002 null;
        "model" = mkOverride 1002 null;
        "params" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.AIServiceSpecAzureOpenaiApiKeySecret" = {

      options = {
        "secretName" = mkOption {
          description = "";
          type = types.str;
        };
      };

      config = { };

    };
    "hub.traefik.io.v1alpha1.AIServiceSpecAzureOpenaiParams" = {

      options = {
        "frequencyPenalty" = mkOption {
          description = "";
          type = types.nullOr (types.either types.int types.float);
        };
        "maxTokens" = mkOption {
          description = "";
          type = types.nullOr types.int;
        };
        "presencePenalty" = mkOption {
          description = "";
          type = types.nullOr (types.either types.int types.float);
        };
        "temperature" = mkOption {
          description = "";
          type = types.nullOr (types.either types.int types.float);
        };
        "topP" = mkOption {
          description = "";
          type = types.nullOr (types.either types.int types.float);
        };
      };

      config = {
        "frequencyPenalty" = mkOverride 1002 null;
        "maxTokens" = mkOverride 1002 null;
        "presencePenalty" = mkOverride 1002 null;
        "temperature" = mkOverride 1002 null;
        "topP" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.AIServiceSpecBedrock" = {

      options = {
        "model" = mkOption {
          description = "";
          type = types.nullOr types.str;
        };
        "params" = mkOption {
          description = "Params holds the LLM hyperparameters.";
          type = types.nullOr (submoduleOf "hub.traefik.io.v1alpha1.AIServiceSpecBedrockParams");
        };
        "region" = mkOption {
          description = "";
          type = types.nullOr types.str;
        };
        "systemMessage" = mkOption {
          description = "";
          type = types.nullOr types.bool;
        };
      };

      config = {
        "model" = mkOverride 1002 null;
        "params" = mkOverride 1002 null;
        "region" = mkOverride 1002 null;
        "systemMessage" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.AIServiceSpecBedrockParams" = {

      options = {
        "frequencyPenalty" = mkOption {
          description = "";
          type = types.nullOr (types.either types.int types.float);
        };
        "maxTokens" = mkOption {
          description = "";
          type = types.nullOr types.int;
        };
        "presencePenalty" = mkOption {
          description = "";
          type = types.nullOr (types.either types.int types.float);
        };
        "temperature" = mkOption {
          description = "";
          type = types.nullOr (types.either types.int types.float);
        };
        "topP" = mkOption {
          description = "";
          type = types.nullOr (types.either types.int types.float);
        };
      };

      config = {
        "frequencyPenalty" = mkOverride 1002 null;
        "maxTokens" = mkOverride 1002 null;
        "presencePenalty" = mkOverride 1002 null;
        "temperature" = mkOverride 1002 null;
        "topP" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.AIServiceSpecCohere" = {

      options = {
        "model" = mkOption {
          description = "";
          type = types.nullOr types.str;
        };
        "params" = mkOption {
          description = "Params holds the LLM hyperparameters.";
          type = types.nullOr (submoduleOf "hub.traefik.io.v1alpha1.AIServiceSpecCohereParams");
        };
        "token" = mkOption {
          description = "SecretReference references a kubernetes secret.";
          type = types.nullOr (submoduleOf "hub.traefik.io.v1alpha1.AIServiceSpecCohereToken");
        };
      };

      config = {
        "model" = mkOverride 1002 null;
        "params" = mkOverride 1002 null;
        "token" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.AIServiceSpecCohereParams" = {

      options = {
        "frequencyPenalty" = mkOption {
          description = "";
          type = types.nullOr (types.either types.int types.float);
        };
        "maxTokens" = mkOption {
          description = "";
          type = types.nullOr types.int;
        };
        "presencePenalty" = mkOption {
          description = "";
          type = types.nullOr (types.either types.int types.float);
        };
        "temperature" = mkOption {
          description = "";
          type = types.nullOr (types.either types.int types.float);
        };
        "topP" = mkOption {
          description = "";
          type = types.nullOr (types.either types.int types.float);
        };
      };

      config = {
        "frequencyPenalty" = mkOverride 1002 null;
        "maxTokens" = mkOverride 1002 null;
        "presencePenalty" = mkOverride 1002 null;
        "temperature" = mkOverride 1002 null;
        "topP" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.AIServiceSpecCohereToken" = {

      options = {
        "secretName" = mkOption {
          description = "";
          type = types.str;
        };
      };

      config = { };

    };
    "hub.traefik.io.v1alpha1.AIServiceSpecDeepSeek" = {

      options = {
        "baseUrl" = mkOption {
          description = "";
          type = types.nullOr types.str;
        };
        "model" = mkOption {
          description = "";
          type = types.nullOr types.str;
        };
        "params" = mkOption {
          description = "Params holds the LLM hyperparameters.";
          type = types.nullOr (submoduleOf "hub.traefik.io.v1alpha1.AIServiceSpecDeepSeekParams");
        };
        "token" = mkOption {
          description = "SecretReference references a kubernetes secret.";
          type = types.nullOr (submoduleOf "hub.traefik.io.v1alpha1.AIServiceSpecDeepSeekToken");
        };
      };

      config = {
        "baseUrl" = mkOverride 1002 null;
        "model" = mkOverride 1002 null;
        "params" = mkOverride 1002 null;
        "token" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.AIServiceSpecDeepSeekParams" = {

      options = {
        "frequencyPenalty" = mkOption {
          description = "";
          type = types.nullOr (types.either types.int types.float);
        };
        "maxTokens" = mkOption {
          description = "";
          type = types.nullOr types.int;
        };
        "presencePenalty" = mkOption {
          description = "";
          type = types.nullOr (types.either types.int types.float);
        };
        "temperature" = mkOption {
          description = "";
          type = types.nullOr (types.either types.int types.float);
        };
        "topP" = mkOption {
          description = "";
          type = types.nullOr (types.either types.int types.float);
        };
      };

      config = {
        "frequencyPenalty" = mkOverride 1002 null;
        "maxTokens" = mkOverride 1002 null;
        "presencePenalty" = mkOverride 1002 null;
        "temperature" = mkOverride 1002 null;
        "topP" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.AIServiceSpecDeepSeekToken" = {

      options = {
        "secretName" = mkOption {
          description = "";
          type = types.str;
        };
      };

      config = { };

    };
    "hub.traefik.io.v1alpha1.AIServiceSpecGemini" = {

      options = {
        "apiKey" = mkOption {
          description = "SecretReference references a kubernetes secret.";
          type = types.nullOr (submoduleOf "hub.traefik.io.v1alpha1.AIServiceSpecGeminiApiKey");
        };
        "model" = mkOption {
          description = "";
          type = types.nullOr types.str;
        };
        "params" = mkOption {
          description = "Params holds the LLM hyperparameters.";
          type = types.nullOr (submoduleOf "hub.traefik.io.v1alpha1.AIServiceSpecGeminiParams");
        };
      };

      config = {
        "apiKey" = mkOverride 1002 null;
        "model" = mkOverride 1002 null;
        "params" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.AIServiceSpecGeminiApiKey" = {

      options = {
        "secretName" = mkOption {
          description = "";
          type = types.str;
        };
      };

      config = { };

    };
    "hub.traefik.io.v1alpha1.AIServiceSpecGeminiParams" = {

      options = {
        "frequencyPenalty" = mkOption {
          description = "";
          type = types.nullOr (types.either types.int types.float);
        };
        "maxTokens" = mkOption {
          description = "";
          type = types.nullOr types.int;
        };
        "presencePenalty" = mkOption {
          description = "";
          type = types.nullOr (types.either types.int types.float);
        };
        "temperature" = mkOption {
          description = "";
          type = types.nullOr (types.either types.int types.float);
        };
        "topP" = mkOption {
          description = "";
          type = types.nullOr (types.either types.int types.float);
        };
      };

      config = {
        "frequencyPenalty" = mkOverride 1002 null;
        "maxTokens" = mkOverride 1002 null;
        "presencePenalty" = mkOverride 1002 null;
        "temperature" = mkOverride 1002 null;
        "topP" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.AIServiceSpecMistral" = {

      options = {
        "apiKey" = mkOption {
          description = "SecretReference references a kubernetes secret.";
          type = types.nullOr (submoduleOf "hub.traefik.io.v1alpha1.AIServiceSpecMistralApiKey");
        };
        "model" = mkOption {
          description = "";
          type = types.nullOr types.str;
        };
        "params" = mkOption {
          description = "Params holds the LLM hyperparameters.";
          type = types.nullOr (submoduleOf "hub.traefik.io.v1alpha1.AIServiceSpecMistralParams");
        };
      };

      config = {
        "apiKey" = mkOverride 1002 null;
        "model" = mkOverride 1002 null;
        "params" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.AIServiceSpecMistralApiKey" = {

      options = {
        "secretName" = mkOption {
          description = "";
          type = types.str;
        };
      };

      config = { };

    };
    "hub.traefik.io.v1alpha1.AIServiceSpecMistralParams" = {

      options = {
        "frequencyPenalty" = mkOption {
          description = "";
          type = types.nullOr (types.either types.int types.float);
        };
        "maxTokens" = mkOption {
          description = "";
          type = types.nullOr types.int;
        };
        "presencePenalty" = mkOption {
          description = "";
          type = types.nullOr (types.either types.int types.float);
        };
        "temperature" = mkOption {
          description = "";
          type = types.nullOr (types.either types.int types.float);
        };
        "topP" = mkOption {
          description = "";
          type = types.nullOr (types.either types.int types.float);
        };
      };

      config = {
        "frequencyPenalty" = mkOverride 1002 null;
        "maxTokens" = mkOverride 1002 null;
        "presencePenalty" = mkOverride 1002 null;
        "temperature" = mkOverride 1002 null;
        "topP" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.AIServiceSpecOllama" = {

      options = {
        "baseUrl" = mkOption {
          description = "";
          type = types.str;
        };
        "model" = mkOption {
          description = "";
          type = types.nullOr types.str;
        };
        "params" = mkOption {
          description = "Params holds the LLM hyperparameters.";
          type = types.nullOr (submoduleOf "hub.traefik.io.v1alpha1.AIServiceSpecOllamaParams");
        };
      };

      config = {
        "model" = mkOverride 1002 null;
        "params" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.AIServiceSpecOllamaParams" = {

      options = {
        "frequencyPenalty" = mkOption {
          description = "";
          type = types.nullOr (types.either types.int types.float);
        };
        "maxTokens" = mkOption {
          description = "";
          type = types.nullOr types.int;
        };
        "presencePenalty" = mkOption {
          description = "";
          type = types.nullOr (types.either types.int types.float);
        };
        "temperature" = mkOption {
          description = "";
          type = types.nullOr (types.either types.int types.float);
        };
        "topP" = mkOption {
          description = "";
          type = types.nullOr (types.either types.int types.float);
        };
      };

      config = {
        "frequencyPenalty" = mkOverride 1002 null;
        "maxTokens" = mkOverride 1002 null;
        "presencePenalty" = mkOverride 1002 null;
        "temperature" = mkOverride 1002 null;
        "topP" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.AIServiceSpecOpenai" = {

      options = {
        "baseUrl" = mkOption {
          description = "";
          type = types.nullOr types.str;
        };
        "model" = mkOption {
          description = "";
          type = types.nullOr types.str;
        };
        "params" = mkOption {
          description = "Params holds the LLM hyperparameters.";
          type = types.nullOr (submoduleOf "hub.traefik.io.v1alpha1.AIServiceSpecOpenaiParams");
        };
        "token" = mkOption {
          description = "SecretReference references a kubernetes secret.";
          type = types.nullOr (submoduleOf "hub.traefik.io.v1alpha1.AIServiceSpecOpenaiToken");
        };
      };

      config = {
        "baseUrl" = mkOverride 1002 null;
        "model" = mkOverride 1002 null;
        "params" = mkOverride 1002 null;
        "token" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.AIServiceSpecOpenaiParams" = {

      options = {
        "frequencyPenalty" = mkOption {
          description = "";
          type = types.nullOr (types.either types.int types.float);
        };
        "maxTokens" = mkOption {
          description = "";
          type = types.nullOr types.int;
        };
        "presencePenalty" = mkOption {
          description = "";
          type = types.nullOr (types.either types.int types.float);
        };
        "temperature" = mkOption {
          description = "";
          type = types.nullOr (types.either types.int types.float);
        };
        "topP" = mkOption {
          description = "";
          type = types.nullOr (types.either types.int types.float);
        };
      };

      config = {
        "frequencyPenalty" = mkOverride 1002 null;
        "maxTokens" = mkOverride 1002 null;
        "presencePenalty" = mkOverride 1002 null;
        "temperature" = mkOverride 1002 null;
        "topP" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.AIServiceSpecOpenaiToken" = {

      options = {
        "secretName" = mkOption {
          description = "";
          type = types.str;
        };
      };

      config = { };

    };
    "hub.traefik.io.v1alpha1.AIServiceSpecQWen" = {

      options = {
        "baseUrl" = mkOption {
          description = "";
          type = types.nullOr types.str;
        };
        "model" = mkOption {
          description = "";
          type = types.nullOr types.str;
        };
        "params" = mkOption {
          description = "Params holds the LLM hyperparameters.";
          type = types.nullOr (submoduleOf "hub.traefik.io.v1alpha1.AIServiceSpecQWenParams");
        };
        "token" = mkOption {
          description = "SecretReference references a kubernetes secret.";
          type = types.nullOr (submoduleOf "hub.traefik.io.v1alpha1.AIServiceSpecQWenToken");
        };
      };

      config = {
        "baseUrl" = mkOverride 1002 null;
        "model" = mkOverride 1002 null;
        "params" = mkOverride 1002 null;
        "token" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.AIServiceSpecQWenParams" = {

      options = {
        "frequencyPenalty" = mkOption {
          description = "";
          type = types.nullOr (types.either types.int types.float);
        };
        "maxTokens" = mkOption {
          description = "";
          type = types.nullOr types.int;
        };
        "presencePenalty" = mkOption {
          description = "";
          type = types.nullOr (types.either types.int types.float);
        };
        "temperature" = mkOption {
          description = "";
          type = types.nullOr (types.either types.int types.float);
        };
        "topP" = mkOption {
          description = "";
          type = types.nullOr (types.either types.int types.float);
        };
      };

      config = {
        "frequencyPenalty" = mkOverride 1002 null;
        "maxTokens" = mkOverride 1002 null;
        "presencePenalty" = mkOverride 1002 null;
        "temperature" = mkOverride 1002 null;
        "topP" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.AIServiceSpecQWenToken" = {

      options = {
        "secretName" = mkOption {
          description = "";
          type = types.str;
        };
      };

      config = { };

    };
    "hub.traefik.io.v1alpha1.API" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object.\nServers should convert recognized schemas to the latest internal value, and\nmay reject unrecognized values.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = types.nullOr types.str;
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents.\nServers may infer this from the endpoint the client submits requests to.\nCannot be updated.\nIn CamelCase.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = types.nullOr types.str;
        };
        "metadata" = mkOption {
          description = "Standard object's metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = types.nullOr (globalSubmoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta");
        };
        "spec" = mkOption {
          description = "APISpec describes the API.";
          type = types.nullOr (submoduleOf "hub.traefik.io.v1alpha1.APISpec");
        };
        "status" = mkOption {
          description = "The current status of this API.";
          type = types.nullOr (submoduleOf "hub.traefik.io.v1alpha1.APIStatus");
        };
      };

      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "spec" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.APIAuth" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object.\nServers should convert recognized schemas to the latest internal value, and\nmay reject unrecognized values.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = types.nullOr types.str;
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents.\nServers may infer this from the endpoint the client submits requests to.\nCannot be updated.\nIn CamelCase.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = types.nullOr types.str;
        };
        "metadata" = mkOption {
          description = "Standard object's metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = types.nullOr (globalSubmoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta");
        };
        "spec" = mkOption {
          description = "The desired behavior of this APIAuth.";
          type = types.nullOr (submoduleOf "hub.traefik.io.v1alpha1.APIAuthSpec");
        };
        "status" = mkOption {
          description = "The current status of this APIAuth.";
          type = types.nullOr (submoduleOf "hub.traefik.io.v1alpha1.APIAuthStatus");
        };
      };

      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "spec" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.APIAuthSpec" = {

      options = {
        "apiKey" = mkOption {
          description = "APIKey configures API key authentication.";
          type = types.nullOr types.attrs;
        };
        "isDefault" = mkOption {
          description = "IsDefault specifies if this APIAuth should be used as the default API authentication method for the namespace.\nOnly one APIAuth per namespace should have isDefault set to true.";
          type = types.bool;
        };
        "jwt" = mkOption {
          description = "JWT configures JWT authentication.";
          type = types.nullOr (submoduleOf "hub.traefik.io.v1alpha1.APIAuthSpecJwt");
        };
        "ldap" = mkOption {
          description = "LDAP configures LDAP authentication.";
          type = types.nullOr (submoduleOf "hub.traefik.io.v1alpha1.APIAuthSpecLdap");
        };
      };

      config = {
        "apiKey" = mkOverride 1002 null;
        "jwt" = mkOverride 1002 null;
        "ldap" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.APIAuthSpecJwt" = {

      options = {
        "appIdClaim" = mkOption {
          description = "AppIDClaim is the name of the claim holding the identifier of the application.\nThis field is sometimes named `client_id`.";
          type = types.str;
        };
        "forwardHeaders" = mkOption {
          description = "ForwardHeaders specifies additional headers to forward with the request.";
          type = types.nullOr (types.attrsOf types.str);
        };
        "jwksFile" = mkOption {
          description = "JWKSFile contains the JWKS file content for JWT verification.\nMutually exclusive with SigningSecretName, PublicKey, JWKSURL, and TrustedIssuers.";
          type = types.nullOr types.str;
        };
        "jwksUrl" = mkOption {
          description = "JWKSURL is the URL to fetch the JWKS for JWT verification.\nMutually exclusive with SigningSecretName, PublicKey, JWKSFile, and TrustedIssuers.\nDeprecated: Use TrustedIssuers instead for more flexible JWKS configuration with issuer validation.";
          type = types.nullOr types.str;
        };
        "publicKey" = mkOption {
          description = "PublicKey is the PEM-encoded public key for JWT verification.\nMutually exclusive with SigningSecretName, JWKSFile, JWKSURL, and TrustedIssuers.";
          type = types.nullOr types.str;
        };
        "signingSecretName" = mkOption {
          description = "SigningSecretName is the name of the Kubernetes Secret containing the signing secret.\nThe secret must be of type Opaque and contain a key named 'value'.\nMutually exclusive with PublicKey, JWKSFile, JWKSURL, and TrustedIssuers.";
          type = types.nullOr types.str;
        };
        "stripAuthorizationHeader" = mkOption {
          description = "StripAuthorizationHeader determines whether to strip the Authorization header before forwarding the request.";
          type = types.nullOr types.bool;
        };
        "tokenNameClaim" = mkOption {
          description = "TokenNameClaim is the name of the claim holding the name of the token.\nThis name, if provided, will be used in the metrics.";
          type = types.nullOr types.str;
        };
        "tokenQueryKey" = mkOption {
          description = "TokenQueryKey specifies the query parameter name for the JWT token.";
          type = types.nullOr types.str;
        };
        "trustedIssuers" = mkOption {
          description = "TrustedIssuers defines multiple JWKS providers with optional issuer validation.\nMutually exclusive with SigningSecretName, PublicKey, JWKSFile, and JWKSURL.";
          type = types.nullOr (
            types.listOf (submoduleOf "hub.traefik.io.v1alpha1.APIAuthSpecJwtTrustedIssuers")
          );
        };
      };

      config = {
        "forwardHeaders" = mkOverride 1002 null;
        "jwksFile" = mkOverride 1002 null;
        "jwksUrl" = mkOverride 1002 null;
        "publicKey" = mkOverride 1002 null;
        "signingSecretName" = mkOverride 1002 null;
        "stripAuthorizationHeader" = mkOverride 1002 null;
        "tokenNameClaim" = mkOverride 1002 null;
        "tokenQueryKey" = mkOverride 1002 null;
        "trustedIssuers" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.APIAuthSpecJwtTrustedIssuers" = {

      options = {
        "issuer" = mkOption {
          description = "Issuer is the expected value of the \"iss\" claim.\nIf specified, tokens must have this exact issuer to be validated against this JWKS.\nThe issuer value must match exactly, including trailing slashes and URL encoding.\nIf omitted, this JWKS acts as a fallback for any issuer.";
          type = types.nullOr types.str;
        };
        "jwksUrl" = mkOption {
          description = "JWKSURL is the URL to fetch the JWKS from.";
          type = types.str;
        };
      };

      config = {
        "issuer" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.APIAuthSpecLdap" = {

      options = {
        "attribute" = mkOption {
          description = "Attribute is the LDAP object attribute used to form a bind DN when sending bind queries.\nThe bind DN is formed as <Attribute>=<Username>,<BaseDN>.";
          type = types.nullOr types.str;
        };
        "baseDn" = mkOption {
          description = "BaseDN is the base domain name that should be used for bind and search queries.";
          type = types.str;
        };
        "bindDn" = mkOption {
          description = "BindDN is the domain name to bind to in order to authenticate to the LDAP server when running in search mode.\nIf empty, an anonymous bind will be done.";
          type = types.nullOr types.str;
        };
        "bindPasswordSecretName" = mkOption {
          description = "BindPasswordSecretName is the name of the Kubernetes Secret containing the password for the bind DN.\nThe secret must contain a key named 'password'.";
          type = types.nullOr types.str;
        };
        "certificateAuthority" = mkOption {
          description = "CertificateAuthority is a PEM-encoded certificate to use to establish a connection with the LDAP server if the\nconnection uses TLS but that the certificate was signed by a custom Certificate Authority.";
          type = types.nullOr types.str;
        };
        "insecureSkipVerify" = mkOption {
          description = "InsecureSkipVerify controls whether the server's certificate chain and host name is verified.";
          type = types.nullOr types.bool;
        };
        "searchFilter" = mkOption {
          description = "SearchFilter is used to filter LDAP search queries.\nExample: (&(objectClass=inetOrgPerson)(gidNumber=500)(uid=%s))\n%s can be used as a placeholder for the username.";
          type = types.nullOr types.str;
        };
        "startTls" = mkOption {
          description = "StartTLS instructs the middleware to issue a StartTLS request when initializing the connection with the LDAP server.";
          type = types.nullOr types.bool;
        };
        "url" = mkOption {
          description = "URL is the URL of the LDAP server, including the protocol (ldap or ldaps) and the port.";
          type = types.str;
        };
      };

      config = {
        "attribute" = mkOverride 1002 null;
        "bindDn" = mkOverride 1002 null;
        "bindPasswordSecretName" = mkOverride 1002 null;
        "certificateAuthority" = mkOverride 1002 null;
        "insecureSkipVerify" = mkOverride 1002 null;
        "searchFilter" = mkOverride 1002 null;
        "startTls" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.APIAuthStatus" = {

      options = {
        "conditions" = mkOption {
          description = "";
          type = types.nullOr (types.listOf (submoduleOf "hub.traefik.io.v1alpha1.APIAuthStatusConditions"));
        };
        "hash" = mkOption {
          description = "Hash is a hash representing the APIAuth.";
          type = types.nullOr types.str;
        };
        "syncedAt" = mkOption {
          description = "";
          type = types.nullOr types.str;
        };
        "version" = mkOption {
          description = "";
          type = types.nullOr types.str;
        };
      };

      config = {
        "conditions" = mkOverride 1002 null;
        "hash" = mkOverride 1002 null;
        "syncedAt" = mkOverride 1002 null;
        "version" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.APIAuthStatusConditions" = {

      options = {
        "lastTransitionTime" = mkOption {
          description = "lastTransitionTime is the last time the condition transitioned from one status to another.\nThis should be when the underlying condition changed.  If that is not known, then using the time when the API field changed is acceptable.";
          type = types.str;
        };
        "message" = mkOption {
          description = "message is a human readable message indicating details about the transition.\nThis may be an empty string.";
          type = types.str;
        };
        "observedGeneration" = mkOption {
          description = "observedGeneration represents the .metadata.generation that the condition was set based upon.\nFor instance, if .metadata.generation is currently 12, but the .status.conditions[x].observedGeneration is 9, the condition is out of date\nwith respect to the current state of the instance.";
          type = types.nullOr types.int;
        };
        "reason" = mkOption {
          description = "reason contains a programmatic identifier indicating the reason for the condition's last transition.\nProducers of specific condition types may define expected values and meanings for this field,\nand whether the values are considered a guaranteed API.\nThe value should be a CamelCase string.\nThis field may not be empty.";
          type = types.str;
        };
        "status" = mkOption {
          description = "status of the condition, one of True, False, Unknown.";
          type = types.str;
        };
        "type" = mkOption {
          description = "type of condition in CamelCase or in foo.example.com/CamelCase.";
          type = types.str;
        };
      };

      config = {
        "observedGeneration" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.APIBundle" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object.\nServers should convert recognized schemas to the latest internal value, and\nmay reject unrecognized values.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = types.nullOr types.str;
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents.\nServers may infer this from the endpoint the client submits requests to.\nCannot be updated.\nIn CamelCase.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = types.nullOr types.str;
        };
        "metadata" = mkOption {
          description = "Standard object's metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = types.nullOr (globalSubmoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta");
        };
        "spec" = mkOption {
          description = "The desired behavior of this APIBundle.";
          type = types.nullOr (submoduleOf "hub.traefik.io.v1alpha1.APIBundleSpec");
        };
        "status" = mkOption {
          description = "The current status of this APIBundle.";
          type = types.nullOr (submoduleOf "hub.traefik.io.v1alpha1.APIBundleStatus");
        };
      };

      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "spec" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.APIBundleSpec" = {

      options = {
        "apiSelector" = mkOption {
          description = "APISelector selects the APIs that will be accessible to the configured audience.\nMultiple APIBundles can select the same set of APIs.\nThis field is optional and follows standard label selector semantics.\nAn empty APISelector matches any API.";
          type = types.nullOr (submoduleOf "hub.traefik.io.v1alpha1.APIBundleSpecApiSelector");
        };
        "apis" = mkOption {
          description = "APIs defines a set of APIs that will be accessible to the configured audience.\nMultiple APIBundles can select the same APIs.\nWhen combined with APISelector, this set of APIs is appended to the matching APIs.";
          type = types.nullOr (
            coerceAttrsOfSubmodulesToListByKey "hub.traefik.io.v1alpha1.APIBundleSpecApis" "name" [ ]
          );
          apply = attrsToList;
        };
        "title" = mkOption {
          description = "Title is the human-readable name of the APIBundle that will be used on the portal.";
          type = types.nullOr types.str;
        };
      };

      config = {
        "apiSelector" = mkOverride 1002 null;
        "apis" = mkOverride 1002 null;
        "title" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.APIBundleSpecApiSelector" = {

      options = {
        "matchExpressions" = mkOption {
          description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
          type = types.nullOr (
            types.listOf (submoduleOf "hub.traefik.io.v1alpha1.APIBundleSpecApiSelectorMatchExpressions")
          );
        };
        "matchLabels" = mkOption {
          description = "matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels\nmap is equivalent to an element of matchExpressions, whose key field is \"key\", the\noperator is \"In\", and the values array contains only \"value\". The requirements are ANDed.";
          type = types.nullOr (types.attrsOf types.str);
        };
      };

      config = {
        "matchExpressions" = mkOverride 1002 null;
        "matchLabels" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.APIBundleSpecApiSelectorMatchExpressions" = {

      options = {
        "key" = mkOption {
          description = "key is the label key that the selector applies to.";
          type = types.str;
        };
        "operator" = mkOption {
          description = "operator represents a key's relationship to a set of values.\nValid operators are In, NotIn, Exists and DoesNotExist.";
          type = types.str;
        };
        "values" = mkOption {
          description = "values is an array of string values. If the operator is In or NotIn,\nthe values array must be non-empty. If the operator is Exists or DoesNotExist,\nthe values array must be empty. This array is replaced during a strategic\nmerge patch.";
          type = types.nullOr (types.listOf types.str);
        };
      };

      config = {
        "values" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.APIBundleSpecApis" = {

      options = {
        "name" = mkOption {
          description = "Name of the API.";
          type = types.str;
        };
      };

      config = { };

    };
    "hub.traefik.io.v1alpha1.APIBundleStatus" = {

      options = {
        "conditions" = mkOption {
          description = "Conditions is the list of status conditions.";
          type = types.nullOr (
            types.listOf (submoduleOf "hub.traefik.io.v1alpha1.APIBundleStatusConditions")
          );
        };
        "hash" = mkOption {
          description = "Hash is a hash representing the APIBundle.";
          type = types.nullOr types.str;
        };
        "resolvedApis" = mkOption {
          description = "ResolvedAPIs is the list of APIs that were successfully resolved.";
          type = types.nullOr (
            coerceAttrsOfSubmodulesToListByKey "hub.traefik.io.v1alpha1.APIBundleStatusResolvedApis" "name" [ ]
          );
          apply = attrsToList;
        };
        "syncedAt" = mkOption {
          description = "";
          type = types.nullOr types.str;
        };
        "unresolvedApis" = mkOption {
          description = "UnresolvedAPIs is the list of APIs that could not be resolved.";
          type = types.nullOr (
            coerceAttrsOfSubmodulesToListByKey "hub.traefik.io.v1alpha1.APIBundleStatusUnresolvedApis" "name"
              [ ]
          );
          apply = attrsToList;
        };
        "version" = mkOption {
          description = "";
          type = types.nullOr types.str;
        };
      };

      config = {
        "conditions" = mkOverride 1002 null;
        "hash" = mkOverride 1002 null;
        "resolvedApis" = mkOverride 1002 null;
        "syncedAt" = mkOverride 1002 null;
        "unresolvedApis" = mkOverride 1002 null;
        "version" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.APIBundleStatusConditions" = {

      options = {
        "lastTransitionTime" = mkOption {
          description = "lastTransitionTime is the last time the condition transitioned from one status to another.\nThis should be when the underlying condition changed.  If that is not known, then using the time when the API field changed is acceptable.";
          type = types.str;
        };
        "message" = mkOption {
          description = "message is a human readable message indicating details about the transition.\nThis may be an empty string.";
          type = types.str;
        };
        "observedGeneration" = mkOption {
          description = "observedGeneration represents the .metadata.generation that the condition was set based upon.\nFor instance, if .metadata.generation is currently 12, but the .status.conditions[x].observedGeneration is 9, the condition is out of date\nwith respect to the current state of the instance.";
          type = types.nullOr types.int;
        };
        "reason" = mkOption {
          description = "reason contains a programmatic identifier indicating the reason for the condition's last transition.\nProducers of specific condition types may define expected values and meanings for this field,\nand whether the values are considered a guaranteed API.\nThe value should be a CamelCase string.\nThis field may not be empty.";
          type = types.str;
        };
        "status" = mkOption {
          description = "status of the condition, one of True, False, Unknown.";
          type = types.str;
        };
        "type" = mkOption {
          description = "type of condition in CamelCase or in foo.example.com/CamelCase.";
          type = types.str;
        };
      };

      config = {
        "observedGeneration" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.APIBundleStatusResolvedApis" = {

      options = {
        "name" = mkOption {
          description = "Name of the API.";
          type = types.str;
        };
      };

      config = { };

    };
    "hub.traefik.io.v1alpha1.APIBundleStatusUnresolvedApis" = {

      options = {
        "name" = mkOption {
          description = "Name of the API.";
          type = types.str;
        };
      };

      config = { };

    };
    "hub.traefik.io.v1alpha1.APICatalogItem" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object.\nServers should convert recognized schemas to the latest internal value, and\nmay reject unrecognized values.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = types.nullOr types.str;
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents.\nServers may infer this from the endpoint the client submits requests to.\nCannot be updated.\nIn CamelCase.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = types.nullOr types.str;
        };
        "metadata" = mkOption {
          description = "Standard object's metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = types.nullOr (globalSubmoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta");
        };
        "spec" = mkOption {
          description = "The desired behavior of this APICatalogItem.";
          type = types.nullOr (submoduleOf "hub.traefik.io.v1alpha1.APICatalogItemSpec");
        };
        "status" = mkOption {
          description = "The current status of this APICatalogItem.";
          type = types.nullOr (submoduleOf "hub.traefik.io.v1alpha1.APICatalogItemStatus");
        };
      };

      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "spec" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.APICatalogItemSpec" = {

      options = {
        "apiBundles" = mkOption {
          description = "APIBundles defines a set of APIBundle that will be visible to the configured audience.\nMultiple APICatalogItem can select the same APIBundles.";
          type = types.nullOr (
            coerceAttrsOfSubmodulesToListByKey "hub.traefik.io.v1alpha1.APICatalogItemSpecApiBundles" "name" [ ]
          );
          apply = attrsToList;
        };
        "apiPlan" = mkOption {
          description = "APIPlan defines which APIPlan will be available.\nIf multiple APICatalogItem specify the same API with different APIPlan, the API consumer will be able to pick\na plan from this list.";
          type = types.nullOr (submoduleOf "hub.traefik.io.v1alpha1.APICatalogItemSpecApiPlan");
        };
        "apiSelector" = mkOption {
          description = "APISelector selects the APIs that will be visible to the configured audience.\nMultiple APICatalogItem can select the same set of APIs.\nThis field is optional and follows standard label selector semantics.\nAn empty APISelector matches any API.";
          type = types.nullOr (submoduleOf "hub.traefik.io.v1alpha1.APICatalogItemSpecApiSelector");
        };
        "apis" = mkOption {
          description = "APIs defines a set of APIs that will be visible to the configured audience.\nMultiple APICatalogItem can select the same APIs.\nWhen combined with APISelector, this set of APIs is appended to the matching APIs.";
          type = types.nullOr (
            coerceAttrsOfSubmodulesToListByKey "hub.traefik.io.v1alpha1.APICatalogItemSpecApis" "name" [ ]
          );
          apply = attrsToList;
        };
        "everyone" = mkOption {
          description = "Everyone indicates that all users will see these APIs.";
          type = types.nullOr types.bool;
        };
        "groups" = mkOption {
          description = "Groups are the consumer groups that will see the APIs.";
          type = types.nullOr (types.listOf types.str);
        };
        "operationFilter" = mkOption {
          description = "OperationFilter specifies the visible operations on APIs and APIVersions.\nIf not set, all operations are available.\nAn empty OperationFilter prohibits all operations.";
          type = types.nullOr (submoduleOf "hub.traefik.io.v1alpha1.APICatalogItemSpecOperationFilter");
        };
      };

      config = {
        "apiBundles" = mkOverride 1002 null;
        "apiPlan" = mkOverride 1002 null;
        "apiSelector" = mkOverride 1002 null;
        "apis" = mkOverride 1002 null;
        "everyone" = mkOverride 1002 null;
        "groups" = mkOverride 1002 null;
        "operationFilter" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.APICatalogItemSpecApiBundles" = {

      options = {
        "name" = mkOption {
          description = "Name of the APIBundle.";
          type = types.str;
        };
      };

      config = { };

    };
    "hub.traefik.io.v1alpha1.APICatalogItemSpecApiPlan" = {

      options = {
        "name" = mkOption {
          description = "Name of the APIPlan.";
          type = types.str;
        };
      };

      config = { };

    };
    "hub.traefik.io.v1alpha1.APICatalogItemSpecApiSelector" = {

      options = {
        "matchExpressions" = mkOption {
          description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
          type = types.nullOr (
            types.listOf (submoduleOf "hub.traefik.io.v1alpha1.APICatalogItemSpecApiSelectorMatchExpressions")
          );
        };
        "matchLabels" = mkOption {
          description = "matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels\nmap is equivalent to an element of matchExpressions, whose key field is \"key\", the\noperator is \"In\", and the values array contains only \"value\". The requirements are ANDed.";
          type = types.nullOr (types.attrsOf types.str);
        };
      };

      config = {
        "matchExpressions" = mkOverride 1002 null;
        "matchLabels" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.APICatalogItemSpecApiSelectorMatchExpressions" = {

      options = {
        "key" = mkOption {
          description = "key is the label key that the selector applies to.";
          type = types.str;
        };
        "operator" = mkOption {
          description = "operator represents a key's relationship to a set of values.\nValid operators are In, NotIn, Exists and DoesNotExist.";
          type = types.str;
        };
        "values" = mkOption {
          description = "values is an array of string values. If the operator is In or NotIn,\nthe values array must be non-empty. If the operator is Exists or DoesNotExist,\nthe values array must be empty. This array is replaced during a strategic\nmerge patch.";
          type = types.nullOr (types.listOf types.str);
        };
      };

      config = {
        "values" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.APICatalogItemSpecApis" = {

      options = {
        "name" = mkOption {
          description = "Name of the API.";
          type = types.str;
        };
      };

      config = { };

    };
    "hub.traefik.io.v1alpha1.APICatalogItemSpecOperationFilter" = {

      options = {
        "include" = mkOption {
          description = "Include defines the names of OperationSets that will be accessible.";
          type = types.nullOr (types.listOf types.str);
        };
      };

      config = {
        "include" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.APICatalogItemStatus" = {

      options = {
        "conditions" = mkOption {
          description = "Conditions is the list of status conditions.";
          type = types.nullOr (
            types.listOf (submoduleOf "hub.traefik.io.v1alpha1.APICatalogItemStatusConditions")
          );
        };
        "hash" = mkOption {
          description = "Hash is a hash representing the APICatalogItem.";
          type = types.nullOr types.str;
        };
        "resolvedApis" = mkOption {
          description = "ResolvedAPIs is the list of APIs that were successfully resolved.";
          type = types.nullOr (
            coerceAttrsOfSubmodulesToListByKey "hub.traefik.io.v1alpha1.APICatalogItemStatusResolvedApis" "name"
              [ ]
          );
          apply = attrsToList;
        };
        "syncedAt" = mkOption {
          description = "";
          type = types.nullOr types.str;
        };
        "unresolvedApis" = mkOption {
          description = "UnresolvedAPIs is the list of APIs that could not be resolved.";
          type = types.nullOr (
            coerceAttrsOfSubmodulesToListByKey "hub.traefik.io.v1alpha1.APICatalogItemStatusUnresolvedApis"
              "name"
              [ ]
          );
          apply = attrsToList;
        };
        "version" = mkOption {
          description = "";
          type = types.nullOr types.str;
        };
      };

      config = {
        "conditions" = mkOverride 1002 null;
        "hash" = mkOverride 1002 null;
        "resolvedApis" = mkOverride 1002 null;
        "syncedAt" = mkOverride 1002 null;
        "unresolvedApis" = mkOverride 1002 null;
        "version" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.APICatalogItemStatusConditions" = {

      options = {
        "lastTransitionTime" = mkOption {
          description = "lastTransitionTime is the last time the condition transitioned from one status to another.\nThis should be when the underlying condition changed.  If that is not known, then using the time when the API field changed is acceptable.";
          type = types.str;
        };
        "message" = mkOption {
          description = "message is a human readable message indicating details about the transition.\nThis may be an empty string.";
          type = types.str;
        };
        "observedGeneration" = mkOption {
          description = "observedGeneration represents the .metadata.generation that the condition was set based upon.\nFor instance, if .metadata.generation is currently 12, but the .status.conditions[x].observedGeneration is 9, the condition is out of date\nwith respect to the current state of the instance.";
          type = types.nullOr types.int;
        };
        "reason" = mkOption {
          description = "reason contains a programmatic identifier indicating the reason for the condition's last transition.\nProducers of specific condition types may define expected values and meanings for this field,\nand whether the values are considered a guaranteed API.\nThe value should be a CamelCase string.\nThis field may not be empty.";
          type = types.str;
        };
        "status" = mkOption {
          description = "status of the condition, one of True, False, Unknown.";
          type = types.str;
        };
        "type" = mkOption {
          description = "type of condition in CamelCase or in foo.example.com/CamelCase.";
          type = types.str;
        };
      };

      config = {
        "observedGeneration" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.APICatalogItemStatusResolvedApis" = {

      options = {
        "name" = mkOption {
          description = "Name of the API.";
          type = types.str;
        };
      };

      config = { };

    };
    "hub.traefik.io.v1alpha1.APICatalogItemStatusUnresolvedApis" = {

      options = {
        "name" = mkOption {
          description = "Name of the API.";
          type = types.str;
        };
      };

      config = { };

    };
    "hub.traefik.io.v1alpha1.APIPlan" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object.\nServers should convert recognized schemas to the latest internal value, and\nmay reject unrecognized values.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = types.nullOr types.str;
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents.\nServers may infer this from the endpoint the client submits requests to.\nCannot be updated.\nIn CamelCase.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = types.nullOr types.str;
        };
        "metadata" = mkOption {
          description = "Standard object's metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = types.nullOr (globalSubmoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta");
        };
        "spec" = mkOption {
          description = "The desired behavior of this APIPlan.";
          type = types.nullOr (submoduleOf "hub.traefik.io.v1alpha1.APIPlanSpec");
        };
        "status" = mkOption {
          description = "The current status of this APIPlan.";
          type = types.nullOr (submoduleOf "hub.traefik.io.v1alpha1.APIPlanStatus");
        };
      };

      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "spec" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.APIPlanSpec" = {

      options = {
        "description" = mkOption {
          description = "Description describes the plan.";
          type = types.nullOr types.str;
        };
        "quota" = mkOption {
          description = "Quota defines the quota policy.";
          type = types.nullOr (submoduleOf "hub.traefik.io.v1alpha1.APIPlanSpecQuota");
        };
        "rateLimit" = mkOption {
          description = "RateLimit defines the rate limit policy.";
          type = types.nullOr (submoduleOf "hub.traefik.io.v1alpha1.APIPlanSpecRateLimit");
        };
        "title" = mkOption {
          description = "Title is the human-readable name of the plan.";
          type = types.str;
        };
      };

      config = {
        "description" = mkOverride 1002 null;
        "quota" = mkOverride 1002 null;
        "rateLimit" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.APIPlanSpecQuota" = {

      options = {
        "bucket" = mkOption {
          description = "Bucket defines the bucket strategy for the quota.";
          type = types.nullOr types.str;
        };
        "limit" = mkOption {
          description = "Limit is the maximum number of requests per sliding Period.";
          type = types.int;
        };
        "period" = mkOption {
          description = "Period is the unit of time for the Limit.";
          type = types.nullOr types.str;
        };
      };

      config = {
        "bucket" = mkOverride 1002 null;
        "period" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.APIPlanSpecRateLimit" = {

      options = {
        "bucket" = mkOption {
          description = "Bucket defines the bucket strategy for the rate limit.";
          type = types.nullOr types.str;
        };
        "limit" = mkOption {
          description = "Limit is the number of requests per Period used to calculate the regeneration rate.\nTraffic will converge to this rate over time by delaying requests when possible, and dropping them when throttling alone is not enough.";
          type = types.int;
        };
        "period" = mkOption {
          description = "Period is the time unit used to express the rate.\nCombined with Limit, it defines the rate at which request capacity regenerates (Limit ÷ Period).";
          type = types.nullOr types.str;
        };
      };

      config = {
        "bucket" = mkOverride 1002 null;
        "period" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.APIPlanStatus" = {

      options = {
        "conditions" = mkOption {
          description = "";
          type = types.nullOr (types.listOf (submoduleOf "hub.traefik.io.v1alpha1.APIPlanStatusConditions"));
        };
        "hash" = mkOption {
          description = "Hash is a hash representing the APIPlan.";
          type = types.nullOr types.str;
        };
        "syncedAt" = mkOption {
          description = "";
          type = types.nullOr types.str;
        };
        "version" = mkOption {
          description = "";
          type = types.nullOr types.str;
        };
      };

      config = {
        "conditions" = mkOverride 1002 null;
        "hash" = mkOverride 1002 null;
        "syncedAt" = mkOverride 1002 null;
        "version" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.APIPlanStatusConditions" = {

      options = {
        "lastTransitionTime" = mkOption {
          description = "lastTransitionTime is the last time the condition transitioned from one status to another.\nThis should be when the underlying condition changed.  If that is not known, then using the time when the API field changed is acceptable.";
          type = types.str;
        };
        "message" = mkOption {
          description = "message is a human readable message indicating details about the transition.\nThis may be an empty string.";
          type = types.str;
        };
        "observedGeneration" = mkOption {
          description = "observedGeneration represents the .metadata.generation that the condition was set based upon.\nFor instance, if .metadata.generation is currently 12, but the .status.conditions[x].observedGeneration is 9, the condition is out of date\nwith respect to the current state of the instance.";
          type = types.nullOr types.int;
        };
        "reason" = mkOption {
          description = "reason contains a programmatic identifier indicating the reason for the condition's last transition.\nProducers of specific condition types may define expected values and meanings for this field,\nand whether the values are considered a guaranteed API.\nThe value should be a CamelCase string.\nThis field may not be empty.";
          type = types.str;
        };
        "status" = mkOption {
          description = "status of the condition, one of True, False, Unknown.";
          type = types.str;
        };
        "type" = mkOption {
          description = "type of condition in CamelCase or in foo.example.com/CamelCase.";
          type = types.str;
        };
      };

      config = {
        "observedGeneration" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.APIPortal" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object.\nServers should convert recognized schemas to the latest internal value, and\nmay reject unrecognized values.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = types.nullOr types.str;
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents.\nServers may infer this from the endpoint the client submits requests to.\nCannot be updated.\nIn CamelCase.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = types.nullOr types.str;
        };
        "metadata" = mkOption {
          description = "Standard object's metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = types.nullOr (globalSubmoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta");
        };
        "spec" = mkOption {
          description = "The desired behavior of this APIPortal.";
          type = types.nullOr (submoduleOf "hub.traefik.io.v1alpha1.APIPortalSpec");
        };
        "status" = mkOption {
          description = "The current status of this APIPortal.";
          type = types.nullOr (submoduleOf "hub.traefik.io.v1alpha1.APIPortalStatus");
        };
      };

      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "spec" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.APIPortalAuth" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object.\nServers should convert recognized schemas to the latest internal value, and\nmay reject unrecognized values.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = types.nullOr types.str;
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents.\nServers may infer this from the endpoint the client submits requests to.\nCannot be updated.\nIn CamelCase.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = types.nullOr types.str;
        };
        "metadata" = mkOption {
          description = "Standard object's metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = types.nullOr (globalSubmoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta");
        };
        "spec" = mkOption {
          description = "The desired behavior of this APIPortalAuth.";
          type = types.nullOr (submoduleOf "hub.traefik.io.v1alpha1.APIPortalAuthSpec");
        };
        "status" = mkOption {
          description = "The current status of this APIPortalAuth.";
          type = types.nullOr (submoduleOf "hub.traefik.io.v1alpha1.APIPortalAuthStatus");
        };
      };

      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "spec" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.APIPortalAuthSpec" = {

      options = {
        "ldap" = mkOption {
          description = "LDAP configures the LDAP authentication.";
          type = types.nullOr (submoduleOf "hub.traefik.io.v1alpha1.APIPortalAuthSpecLdap");
        };
        "oidc" = mkOption {
          description = "OIDC configures the OIDC authentication.";
          type = types.nullOr (submoduleOf "hub.traefik.io.v1alpha1.APIPortalAuthSpecOidc");
        };
      };

      config = {
        "ldap" = mkOverride 1002 null;
        "oidc" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.APIPortalAuthSpecLdap" = {

      options = {
        "attribute" = mkOption {
          description = "Attribute is the LDAP object attribute used to form a bind DN when sending bind queries.\nThe bind DN is formed as <Attribute>=<Username>,<BaseDN>.";
          type = types.nullOr types.str;
        };
        "attributes" = mkOption {
          description = "Attributes configures LDAP attribute mappings for user attributes.";
          type = types.nullOr (submoduleOf "hub.traefik.io.v1alpha1.APIPortalAuthSpecLdapAttributes");
        };
        "baseDn" = mkOption {
          description = "BaseDN is the base domain name that should be used for bind and search queries.";
          type = types.str;
        };
        "bindDn" = mkOption {
          description = "BindDN is the domain name to bind to in order to authenticate to the LDAP server when running in search mode.\nIf empty, an anonymous bind will be done.";
          type = types.nullOr types.str;
        };
        "bindPasswordSecretName" = mkOption {
          description = "BindPasswordSecretName is the name of the Kubernetes Secret containing the password for the bind DN.\nThe secret must contain a key named 'password'.";
          type = types.nullOr types.str;
        };
        "certificateAuthority" = mkOption {
          description = "CertificateAuthority is a PEM-encoded certificate to use to establish a connection with the LDAP server if the\nconnection uses TLS but that the certificate was signed by a custom Certificate Authority.";
          type = types.nullOr types.str;
        };
        "groups" = mkOption {
          description = "Groups configures group extraction.";
          type = types.nullOr (submoduleOf "hub.traefik.io.v1alpha1.APIPortalAuthSpecLdapGroups");
        };
        "insecureSkipVerify" = mkOption {
          description = "InsecureSkipVerify controls whether the server's certificate chain and host name is verified.";
          type = types.nullOr types.bool;
        };
        "searchFilter" = mkOption {
          description = "SearchFilter is used to filter LDAP search queries.\nExample: (&(objectClass=inetOrgPerson)(gidNumber=500)(uid=%s))\n%s can be used as a placeholder for the username.";
          type = types.nullOr types.str;
        };
        "startTls" = mkOption {
          description = "StartTLS instructs the middleware to issue a StartTLS request when initializing the connection with the LDAP server.";
          type = types.nullOr types.bool;
        };
        "syncedAttributes" = mkOption {
          description = "SyncedAttributes are the user attributes to synchronize with Hub platform.";
          type = types.nullOr (types.listOf types.str);
        };
        "url" = mkOption {
          description = "URL is the URL of the LDAP server, including the protocol (ldap or ldaps) and the port.";
          type = types.str;
        };
      };

      config = {
        "attribute" = mkOverride 1002 null;
        "attributes" = mkOverride 1002 null;
        "bindDn" = mkOverride 1002 null;
        "bindPasswordSecretName" = mkOverride 1002 null;
        "certificateAuthority" = mkOverride 1002 null;
        "groups" = mkOverride 1002 null;
        "insecureSkipVerify" = mkOverride 1002 null;
        "searchFilter" = mkOverride 1002 null;
        "startTls" = mkOverride 1002 null;
        "syncedAttributes" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.APIPortalAuthSpecLdapAttributes" = {

      options = {
        "company" = mkOption {
          description = "Company is the LDAP attribute for user company.";
          type = types.nullOr types.str;
        };
        "email" = mkOption {
          description = "Email is the LDAP attribute for user email.";
          type = types.nullOr types.str;
        };
        "firstname" = mkOption {
          description = "Firstname is the LDAP attribute for user first name.";
          type = types.nullOr types.str;
        };
        "lastname" = mkOption {
          description = "Lastname is the LDAP attribute for user last name.";
          type = types.nullOr types.str;
        };
        "userId" = mkOption {
          description = "UserID is the LDAP attribute for user ID mapping.";
          type = types.nullOr types.str;
        };
      };

      config = {
        "company" = mkOverride 1002 null;
        "email" = mkOverride 1002 null;
        "firstname" = mkOverride 1002 null;
        "lastname" = mkOverride 1002 null;
        "userId" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.APIPortalAuthSpecLdapGroups" = {

      options = {
        "memberOfAttribute" = mkOption {
          description = "MemberOfAttribute is the LDAP attribute containing group memberships (e.g., \"memberOf\").";
          type = types.nullOr types.str;
        };
      };

      config = {
        "memberOfAttribute" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.APIPortalAuthSpecOidc" = {

      options = {
        "claims" = mkOption {
          description = "Claims configures JWT claim mappings for user attributes.";
          type = submoduleOf "hub.traefik.io.v1alpha1.APIPortalAuthSpecOidcClaims";
        };
        "issuerUrl" = mkOption {
          description = "IssuerURL is the OIDC provider issuer URL.";
          type = types.str;
        };
        "scopes" = mkOption {
          description = "Scopes is a list of OAuth2 scopes.";
          type = types.nullOr (types.listOf types.str);
        };
        "secretName" = mkOption {
          description = "SecretName is the name of the Kubernetes Secret containing clientId and clientSecret keys.";
          type = types.str;
        };
        "syncedAttributes" = mkOption {
          description = "SyncedAttributes are the user attributes to synchronize with Hub platform.";
          type = types.nullOr (types.listOf types.str);
        };
      };

      config = {
        "scopes" = mkOverride 1002 null;
        "syncedAttributes" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.APIPortalAuthSpecOidcClaims" = {

      options = {
        "company" = mkOption {
          description = "Company is the JWT claim for user company.";
          type = types.nullOr types.str;
        };
        "email" = mkOption {
          description = "Email is the JWT claim for user email.";
          type = types.nullOr types.str;
        };
        "firstname" = mkOption {
          description = "Firstname is the JWT claim for user first name.";
          type = types.nullOr types.str;
        };
        "groups" = mkOption {
          description = "Groups is the JWT claim for user groups. This field is required for authorization.";
          type = types.str;
        };
        "lastname" = mkOption {
          description = "Lastname is the JWT claim for user last name.";
          type = types.nullOr types.str;
        };
        "userId" = mkOption {
          description = "UserID is the JWT claim for user ID mapping.";
          type = types.nullOr types.str;
        };
      };

      config = {
        "company" = mkOverride 1002 null;
        "email" = mkOverride 1002 null;
        "firstname" = mkOverride 1002 null;
        "lastname" = mkOverride 1002 null;
        "userId" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.APIPortalAuthStatus" = {

      options = {
        "conditions" = mkOption {
          description = "";
          type = types.nullOr (
            types.listOf (submoduleOf "hub.traefik.io.v1alpha1.APIPortalAuthStatusConditions")
          );
        };
        "hash" = mkOption {
          description = "Hash is a hash representing the APIPortalAuth.";
          type = types.nullOr types.str;
        };
        "syncedAt" = mkOption {
          description = "";
          type = types.nullOr types.str;
        };
        "version" = mkOption {
          description = "";
          type = types.nullOr types.str;
        };
      };

      config = {
        "conditions" = mkOverride 1002 null;
        "hash" = mkOverride 1002 null;
        "syncedAt" = mkOverride 1002 null;
        "version" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.APIPortalAuthStatusConditions" = {

      options = {
        "lastTransitionTime" = mkOption {
          description = "lastTransitionTime is the last time the condition transitioned from one status to another.\nThis should be when the underlying condition changed.  If that is not known, then using the time when the API field changed is acceptable.";
          type = types.str;
        };
        "message" = mkOption {
          description = "message is a human readable message indicating details about the transition.\nThis may be an empty string.";
          type = types.str;
        };
        "observedGeneration" = mkOption {
          description = "observedGeneration represents the .metadata.generation that the condition was set based upon.\nFor instance, if .metadata.generation is currently 12, but the .status.conditions[x].observedGeneration is 9, the condition is out of date\nwith respect to the current state of the instance.";
          type = types.nullOr types.int;
        };
        "reason" = mkOption {
          description = "reason contains a programmatic identifier indicating the reason for the condition's last transition.\nProducers of specific condition types may define expected values and meanings for this field,\nand whether the values are considered a guaranteed API.\nThe value should be a CamelCase string.\nThis field may not be empty.";
          type = types.str;
        };
        "status" = mkOption {
          description = "status of the condition, one of True, False, Unknown.";
          type = types.str;
        };
        "type" = mkOption {
          description = "type of condition in CamelCase or in foo.example.com/CamelCase.";
          type = types.str;
        };
      };

      config = {
        "observedGeneration" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.APIPortalSpec" = {

      options = {
        "auth" = mkOption {
          description = "Auth references the APIPortalAuth resource for authentication configuration.";
          type = types.nullOr (submoduleOf "hub.traefik.io.v1alpha1.APIPortalSpecAuth");
        };
        "description" = mkOption {
          description = "Description of the APIPortal.";
          type = types.nullOr types.str;
        };
        "title" = mkOption {
          description = "Title is the public facing name of the APIPortal.";
          type = types.nullOr types.str;
        };
        "trustedUrls" = mkOption {
          description = "TrustedURLs are the urls that are trusted by the OAuth 2.0 authorization server.";
          type = types.listOf types.str;
        };
        "ui" = mkOption {
          description = "UI holds the UI customization options.";
          type = types.nullOr (submoduleOf "hub.traefik.io.v1alpha1.APIPortalSpecUi");
        };
      };

      config = {
        "auth" = mkOverride 1002 null;
        "description" = mkOverride 1002 null;
        "title" = mkOverride 1002 null;
        "ui" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.APIPortalSpecAuth" = {

      options = {
        "name" = mkOption {
          description = "Name is the name of the APIPortalAuth resource.";
          type = types.str;
        };
      };

      config = { };

    };
    "hub.traefik.io.v1alpha1.APIPortalSpecUi" = {

      options = {
        "logoUrl" = mkOption {
          description = "LogoURL is the public URL of the logo.";
          type = types.nullOr types.str;
        };
      };

      config = {
        "logoUrl" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.APIPortalStatus" = {

      options = {
        "conditions" = mkOption {
          description = "";
          type = types.nullOr (
            types.listOf (submoduleOf "hub.traefik.io.v1alpha1.APIPortalStatusConditions")
          );
        };
        "hash" = mkOption {
          description = "Hash is a hash representing the APIPortal.";
          type = types.nullOr types.str;
        };
        "oidc" = mkOption {
          description = "OIDC is the OIDC configuration for accessing the exposed APIPortal WebUI.";
          type = types.nullOr (submoduleOf "hub.traefik.io.v1alpha1.APIPortalStatusOidc");
        };
        "syncedAt" = mkOption {
          description = "";
          type = types.nullOr types.str;
        };
        "version" = mkOption {
          description = "";
          type = types.nullOr types.str;
        };
      };

      config = {
        "conditions" = mkOverride 1002 null;
        "hash" = mkOverride 1002 null;
        "oidc" = mkOverride 1002 null;
        "syncedAt" = mkOverride 1002 null;
        "version" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.APIPortalStatusConditions" = {

      options = {
        "lastTransitionTime" = mkOption {
          description = "lastTransitionTime is the last time the condition transitioned from one status to another.\nThis should be when the underlying condition changed.  If that is not known, then using the time when the API field changed is acceptable.";
          type = types.str;
        };
        "message" = mkOption {
          description = "message is a human readable message indicating details about the transition.\nThis may be an empty string.";
          type = types.str;
        };
        "observedGeneration" = mkOption {
          description = "observedGeneration represents the .metadata.generation that the condition was set based upon.\nFor instance, if .metadata.generation is currently 12, but the .status.conditions[x].observedGeneration is 9, the condition is out of date\nwith respect to the current state of the instance.";
          type = types.nullOr types.int;
        };
        "reason" = mkOption {
          description = "reason contains a programmatic identifier indicating the reason for the condition's last transition.\nProducers of specific condition types may define expected values and meanings for this field,\nand whether the values are considered a guaranteed API.\nThe value should be a CamelCase string.\nThis field may not be empty.";
          type = types.str;
        };
        "status" = mkOption {
          description = "status of the condition, one of True, False, Unknown.";
          type = types.str;
        };
        "type" = mkOption {
          description = "type of condition in CamelCase or in foo.example.com/CamelCase.";
          type = types.str;
        };
      };

      config = {
        "observedGeneration" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.APIPortalStatusOidc" = {

      options = {
        "clientId" = mkOption {
          description = "ClientID is the OIDC ClientID for accessing the exposed APIPortal WebUI.";
          type = types.nullOr types.str;
        };
        "companyClaim" = mkOption {
          description = "CompanyClaim is the name of the JWT claim containing the user company.";
          type = types.nullOr types.str;
        };
        "emailClaim" = mkOption {
          description = "EmailClaim is the name of the JWT claim containing the user email.";
          type = types.nullOr types.str;
        };
        "firstnameClaim" = mkOption {
          description = "FirstnameClaim is the name of the JWT claim containing the user firstname.";
          type = types.nullOr types.str;
        };
        "generic" = mkOption {
          description = "Generic indicates whether or not the APIPortal authentication relies on Generic OIDC.";
          type = types.nullOr types.bool;
        };
        "groupsClaim" = mkOption {
          description = "GroupsClaim is the name of the JWT claim containing the user groups.";
          type = types.nullOr types.str;
        };
        "issuer" = mkOption {
          description = "Issuer is the OIDC issuer for accessing the exposed APIPortal WebUI.";
          type = types.nullOr types.str;
        };
        "lastnameClaim" = mkOption {
          description = "LastnameClaim is the name of the JWT claim containing the user lastname.";
          type = types.nullOr types.str;
        };
        "scopes" = mkOption {
          description = "Scopes is the OIDC scopes for getting user attributes during the authentication to the exposed APIPortal WebUI.";
          type = types.nullOr types.str;
        };
        "secretName" = mkOption {
          description = "SecretName is the name of the secret containing the OIDC ClientSecret for accessing the exposed APIPortal WebUI.";
          type = types.nullOr types.str;
        };
        "syncedAttributes" = mkOption {
          description = "SyncedAttributes configure the user attributes to sync.";
          type = types.nullOr (types.listOf types.str);
        };
        "userIdClaim" = mkOption {
          description = "UserIDClaim is the name of the JWT claim containing the user ID.";
          type = types.nullOr types.str;
        };
      };

      config = {
        "clientId" = mkOverride 1002 null;
        "companyClaim" = mkOverride 1002 null;
        "emailClaim" = mkOverride 1002 null;
        "firstnameClaim" = mkOverride 1002 null;
        "generic" = mkOverride 1002 null;
        "groupsClaim" = mkOverride 1002 null;
        "issuer" = mkOverride 1002 null;
        "lastnameClaim" = mkOverride 1002 null;
        "scopes" = mkOverride 1002 null;
        "secretName" = mkOverride 1002 null;
        "syncedAttributes" = mkOverride 1002 null;
        "userIdClaim" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.APIRateLimit" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object.\nServers should convert recognized schemas to the latest internal value, and\nmay reject unrecognized values.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = types.nullOr types.str;
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents.\nServers may infer this from the endpoint the client submits requests to.\nCannot be updated.\nIn CamelCase.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = types.nullOr types.str;
        };
        "metadata" = mkOption {
          description = "Standard object's metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = types.nullOr (globalSubmoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta");
        };
        "spec" = mkOption {
          description = "The desired behavior of this APIRateLimit.";
          type = types.nullOr (submoduleOf "hub.traefik.io.v1alpha1.APIRateLimitSpec");
        };
        "status" = mkOption {
          description = "The current status of this APIRateLimit.";
          type = types.nullOr (submoduleOf "hub.traefik.io.v1alpha1.APIRateLimitStatus");
        };
      };

      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "spec" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.APIRateLimitSpec" = {

      options = {
        "apiSelector" = mkOption {
          description = "APISelector selects the APIs that will be rate limited.\nMultiple APIRateLimits can select the same set of APIs.\nThis field is optional and follows standard label selector semantics.\nAn empty APISelector matches any API.";
          type = types.nullOr (submoduleOf "hub.traefik.io.v1alpha1.APIRateLimitSpecApiSelector");
        };
        "apis" = mkOption {
          description = "APIs defines a set of APIs that will be rate limited.\nMultiple APIRateLimits can select the same APIs.\nWhen combined with APISelector, this set of APIs is appended to the matching APIs.";
          type = types.nullOr (
            coerceAttrsOfSubmodulesToListByKey "hub.traefik.io.v1alpha1.APIRateLimitSpecApis" "name" [ ]
          );
          apply = attrsToList;
        };
        "everyone" = mkOption {
          description = "Everyone indicates that all users will, by default, be rate limited with this configuration.\nIf an APIRateLimit explicitly target a group, the default rate limit will be ignored.";
          type = types.nullOr types.bool;
        };
        "groups" = mkOption {
          description = "Groups are the consumer groups that will be rate limited.\nMultiple APIRateLimits can target the same set of consumer groups, the most restrictive one applies.\nWhen a consumer belongs to multiple groups, the least restrictive APIRateLimit applies.";
          type = types.nullOr (types.listOf types.str);
        };
        "limit" = mkOption {
          description = "Limit is the maximum number of token in the bucket.";
          type = types.int;
        };
        "period" = mkOption {
          description = "Period is the unit of time for the Limit.";
          type = types.nullOr types.str;
        };
        "strategy" = mkOption {
          description = "Strategy defines how the bucket state will be synchronized between the different Traefik Hub instances.\nIt can be, either \"local\" or \"distributed\".";
          type = types.nullOr types.str;
        };
      };

      config = {
        "apiSelector" = mkOverride 1002 null;
        "apis" = mkOverride 1002 null;
        "everyone" = mkOverride 1002 null;
        "groups" = mkOverride 1002 null;
        "period" = mkOverride 1002 null;
        "strategy" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.APIRateLimitSpecApiSelector" = {

      options = {
        "matchExpressions" = mkOption {
          description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
          type = types.nullOr (
            types.listOf (submoduleOf "hub.traefik.io.v1alpha1.APIRateLimitSpecApiSelectorMatchExpressions")
          );
        };
        "matchLabels" = mkOption {
          description = "matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels\nmap is equivalent to an element of matchExpressions, whose key field is \"key\", the\noperator is \"In\", and the values array contains only \"value\". The requirements are ANDed.";
          type = types.nullOr (types.attrsOf types.str);
        };
      };

      config = {
        "matchExpressions" = mkOverride 1002 null;
        "matchLabels" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.APIRateLimitSpecApiSelectorMatchExpressions" = {

      options = {
        "key" = mkOption {
          description = "key is the label key that the selector applies to.";
          type = types.str;
        };
        "operator" = mkOption {
          description = "operator represents a key's relationship to a set of values.\nValid operators are In, NotIn, Exists and DoesNotExist.";
          type = types.str;
        };
        "values" = mkOption {
          description = "values is an array of string values. If the operator is In or NotIn,\nthe values array must be non-empty. If the operator is Exists or DoesNotExist,\nthe values array must be empty. This array is replaced during a strategic\nmerge patch.";
          type = types.nullOr (types.listOf types.str);
        };
      };

      config = {
        "values" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.APIRateLimitSpecApis" = {

      options = {
        "name" = mkOption {
          description = "Name of the API.";
          type = types.str;
        };
      };

      config = { };

    };
    "hub.traefik.io.v1alpha1.APIRateLimitStatus" = {

      options = {
        "hash" = mkOption {
          description = "Hash is a hash representing the APIRateLimit.";
          type = types.nullOr types.str;
        };
        "syncedAt" = mkOption {
          description = "";
          type = types.nullOr types.str;
        };
        "version" = mkOption {
          description = "";
          type = types.nullOr types.str;
        };
      };

      config = {
        "hash" = mkOverride 1002 null;
        "syncedAt" = mkOverride 1002 null;
        "version" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.APISpec" = {

      options = {
        "cors" = mkOption {
          description = "Cors defines the Cross-Origin Resource Sharing configuration.";
          type = types.nullOr (submoduleOf "hub.traefik.io.v1alpha1.APISpecCors");
        };
        "description" = mkOption {
          description = "Description explains what the API does.";
          type = types.nullOr types.str;
        };
        "openApiSpec" = mkOption {
          description = "OpenAPISpec defines the API contract as an OpenAPI specification.";
          type = types.nullOr (submoduleOf "hub.traefik.io.v1alpha1.APISpecOpenApiSpec");
        };
        "title" = mkOption {
          description = "Title is the human-readable name of the API that will be used on the portal.";
          type = types.nullOr types.str;
        };
        "versions" = mkOption {
          description = "Versions are the different APIVersions available.";
          type = types.nullOr (
            coerceAttrsOfSubmodulesToListByKey "hub.traefik.io.v1alpha1.APISpecVersions" "name" [ ]
          );
          apply = attrsToList;
        };
      };

      config = {
        "cors" = mkOverride 1002 null;
        "description" = mkOverride 1002 null;
        "openApiSpec" = mkOverride 1002 null;
        "title" = mkOverride 1002 null;
        "versions" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.APISpecCors" = {

      options = {
        "addVaryHeader" = mkOption {
          description = "AddVaryHeader defines whether the Vary header is automatically added/updated when the AllowOriginsList is set.";
          type = types.nullOr types.bool;
        };
        "allowCredentials" = mkOption {
          description = "AllowCredentials defines whether the request can include user credentials.";
          type = types.nullOr types.bool;
        };
        "allowHeadersList" = mkOption {
          description = "AllowHeadersList defines the Access-Control-Request-Headers values sent in preflight response.";
          type = types.nullOr (types.listOf types.str);
        };
        "allowMethodsList" = mkOption {
          description = "AllowMethodsList defines the Access-Control-Request-Method values sent in preflight response.";
          type = types.nullOr (types.listOf types.str);
        };
        "allowOriginListRegex" = mkOption {
          description = "AllowOriginListRegex is a list of allowable origins written following the Regular Expression syntax (https://golang.org/pkg/regexp/).";
          type = types.nullOr (types.listOf types.str);
        };
        "allowOriginsList" = mkOption {
          description = "AllowOriginsList is a list of allowable origins. Can also be a wildcard origin \"*\".";
          type = types.nullOr (types.listOf types.str);
        };
        "exposeHeadersList" = mkOption {
          description = "ExposeHeadersList defines the Access-Control-Expose-Headers values sent in preflight response.";
          type = types.nullOr (types.listOf types.str);
        };
        "maxAge" = mkOption {
          description = "MaxAge defines the time that a preflight request may be cached.";
          type = types.nullOr types.int;
        };
      };

      config = {
        "addVaryHeader" = mkOverride 1002 null;
        "allowCredentials" = mkOverride 1002 null;
        "allowHeadersList" = mkOverride 1002 null;
        "allowMethodsList" = mkOverride 1002 null;
        "allowOriginListRegex" = mkOverride 1002 null;
        "allowOriginsList" = mkOverride 1002 null;
        "exposeHeadersList" = mkOverride 1002 null;
        "maxAge" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.APISpecOpenApiSpec" = {

      options = {
        "operationSets" = mkOption {
          description = "OperationSets defines the sets of operations to be referenced for granular filtering in APICatalogItems or ManagedSubscriptions.";
          type = types.nullOr (
            coerceAttrsOfSubmodulesToListByKey "hub.traefik.io.v1alpha1.APISpecOpenApiSpecOperationSets" "name"
              [ ]
          );
          apply = attrsToList;
        };
        "override" = mkOption {
          description = "Override holds data used to override OpenAPI specification.";
          type = types.nullOr (submoduleOf "hub.traefik.io.v1alpha1.APISpecOpenApiSpecOverride");
        };
        "path" = mkOption {
          description = "Path specifies the endpoint path within the Kubernetes Service where the OpenAPI specification can be obtained.\nThe Service queried is determined by the associated Ingress, IngressRoute, or HTTPRoute resource to which the API is attached.\nIt's important to note that this option is incompatible if the Ingress or IngressRoute specifies multiple backend services.\nThe Path must be accessible via a GET request method and should serve a YAML or JSON document containing the OpenAPI specification.";
          type = types.nullOr types.str;
        };
        "url" = mkOption {
          description = "URL is a Traefik Hub agent accessible URL for obtaining the OpenAPI specification.\nThe URL must be accessible via a GET request method and should serve a YAML or JSON document containing the OpenAPI specification.";
          type = types.nullOr types.str;
        };
        "validateRequestMethodAndPath" = mkOption {
          description = "ValidateRequestMethodAndPath validates that the path and method matches an operation defined in the OpenAPI specification.\nThis option overrides the default behavior configured in the static configuration.";
          type = types.nullOr types.bool;
        };
      };

      config = {
        "operationSets" = mkOverride 1002 null;
        "override" = mkOverride 1002 null;
        "path" = mkOverride 1002 null;
        "url" = mkOverride 1002 null;
        "validateRequestMethodAndPath" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.APISpecOpenApiSpecOperationSets" = {

      options = {
        "matchers" = mkOption {
          description = "Matchers defines a list of alternative rules for matching OpenAPI operations.";
          type = types.listOf (submoduleOf "hub.traefik.io.v1alpha1.APISpecOpenApiSpecOperationSetsMatchers");
        };
        "name" = mkOption {
          description = "Name is the name of the OperationSet to reference in APICatalogItems or ManagedSubscriptions.";
          type = types.str;
        };
      };

      config = { };

    };
    "hub.traefik.io.v1alpha1.APISpecOpenApiSpecOperationSetsMatchers" = {

      options = {
        "methods" = mkOption {
          description = "Methods specifies the HTTP methods to be included for selection.";
          type = types.nullOr (types.listOf types.str);
        };
        "path" = mkOption {
          description = "Path specifies the exact path of the operations to select.";
          type = types.nullOr types.str;
        };
        "pathPrefix" = mkOption {
          description = "PathPrefix specifies the path prefix of the operations to select.";
          type = types.nullOr types.str;
        };
        "pathRegex" = mkOption {
          description = "PathRegex specifies a regular expression pattern for matching operations based on their paths.";
          type = types.nullOr types.str;
        };
      };

      config = {
        "methods" = mkOverride 1002 null;
        "path" = mkOverride 1002 null;
        "pathPrefix" = mkOverride 1002 null;
        "pathRegex" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.APISpecOpenApiSpecOverride" = {

      options = {
        "servers" = mkOption {
          description = "";
          type = types.listOf (submoduleOf "hub.traefik.io.v1alpha1.APISpecOpenApiSpecOverrideServers");
        };
      };

      config = { };

    };
    "hub.traefik.io.v1alpha1.APISpecOpenApiSpecOverrideServers" = {

      options = {
        "url" = mkOption {
          description = "";
          type = types.str;
        };
      };

      config = { };

    };
    "hub.traefik.io.v1alpha1.APISpecVersions" = {

      options = {
        "name" = mkOption {
          description = "Name of the APIVersion.";
          type = types.str;
        };
      };

      config = { };

    };
    "hub.traefik.io.v1alpha1.APIStatus" = {

      options = {
        "conditions" = mkOption {
          description = "";
          type = types.nullOr (types.listOf (submoduleOf "hub.traefik.io.v1alpha1.APIStatusConditions"));
        };
        "hash" = mkOption {
          description = "Hash is a hash representing the API.";
          type = types.nullOr types.str;
        };
        "syncedAt" = mkOption {
          description = "";
          type = types.nullOr types.str;
        };
        "version" = mkOption {
          description = "";
          type = types.nullOr types.str;
        };
      };

      config = {
        "conditions" = mkOverride 1002 null;
        "hash" = mkOverride 1002 null;
        "syncedAt" = mkOverride 1002 null;
        "version" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.APIStatusConditions" = {

      options = {
        "lastTransitionTime" = mkOption {
          description = "lastTransitionTime is the last time the condition transitioned from one status to another.\nThis should be when the underlying condition changed.  If that is not known, then using the time when the API field changed is acceptable.";
          type = types.str;
        };
        "message" = mkOption {
          description = "message is a human readable message indicating details about the transition.\nThis may be an empty string.";
          type = types.str;
        };
        "observedGeneration" = mkOption {
          description = "observedGeneration represents the .metadata.generation that the condition was set based upon.\nFor instance, if .metadata.generation is currently 12, but the .status.conditions[x].observedGeneration is 9, the condition is out of date\nwith respect to the current state of the instance.";
          type = types.nullOr types.int;
        };
        "reason" = mkOption {
          description = "reason contains a programmatic identifier indicating the reason for the condition's last transition.\nProducers of specific condition types may define expected values and meanings for this field,\nand whether the values are considered a guaranteed API.\nThe value should be a CamelCase string.\nThis field may not be empty.";
          type = types.str;
        };
        "status" = mkOption {
          description = "status of the condition, one of True, False, Unknown.";
          type = types.str;
        };
        "type" = mkOption {
          description = "type of condition in CamelCase or in foo.example.com/CamelCase.";
          type = types.str;
        };
      };

      config = {
        "observedGeneration" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.APIVersion" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object.\nServers should convert recognized schemas to the latest internal value, and\nmay reject unrecognized values.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = types.nullOr types.str;
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents.\nServers may infer this from the endpoint the client submits requests to.\nCannot be updated.\nIn CamelCase.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = types.nullOr types.str;
        };
        "metadata" = mkOption {
          description = "Standard object's metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = types.nullOr (globalSubmoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta");
        };
        "spec" = mkOption {
          description = "The desired behavior of this APIVersion.";
          type = types.nullOr (submoduleOf "hub.traefik.io.v1alpha1.APIVersionSpec");
        };
        "status" = mkOption {
          description = "The current status of this APIVersion.";
          type = types.nullOr (submoduleOf "hub.traefik.io.v1alpha1.APIVersionStatus");
        };
      };

      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "spec" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.APIVersionSpec" = {

      options = {
        "cors" = mkOption {
          description = "Cors defines the Cross-Origin Resource Sharing configuration.";
          type = types.nullOr (submoduleOf "hub.traefik.io.v1alpha1.APIVersionSpecCors");
        };
        "description" = mkOption {
          description = "Description explains what the APIVersion does.";
          type = types.nullOr types.str;
        };
        "openApiSpec" = mkOption {
          description = "OpenAPISpec defines the API contract as an OpenAPI specification.";
          type = types.nullOr (submoduleOf "hub.traefik.io.v1alpha1.APIVersionSpecOpenApiSpec");
        };
        "release" = mkOption {
          description = "Release is the version number of the API.\nThis value must follow the SemVer format: https://semver.org/";
          type = types.str;
        };
        "title" = mkOption {
          description = "Title is the public facing name of the APIVersion.";
          type = types.nullOr types.str;
        };
      };

      config = {
        "cors" = mkOverride 1002 null;
        "description" = mkOverride 1002 null;
        "openApiSpec" = mkOverride 1002 null;
        "title" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.APIVersionSpecCors" = {

      options = {
        "addVaryHeader" = mkOption {
          description = "AddVaryHeader defines whether the Vary header is automatically added/updated when the AllowOriginsList is set.";
          type = types.nullOr types.bool;
        };
        "allowCredentials" = mkOption {
          description = "AllowCredentials defines whether the request can include user credentials.";
          type = types.nullOr types.bool;
        };
        "allowHeadersList" = mkOption {
          description = "AllowHeadersList defines the Access-Control-Request-Headers values sent in preflight response.";
          type = types.nullOr (types.listOf types.str);
        };
        "allowMethodsList" = mkOption {
          description = "AllowMethodsList defines the Access-Control-Request-Method values sent in preflight response.";
          type = types.nullOr (types.listOf types.str);
        };
        "allowOriginListRegex" = mkOption {
          description = "AllowOriginListRegex is a list of allowable origins written following the Regular Expression syntax (https://golang.org/pkg/regexp/).";
          type = types.nullOr (types.listOf types.str);
        };
        "allowOriginsList" = mkOption {
          description = "AllowOriginsList is a list of allowable origins. Can also be a wildcard origin \"*\".";
          type = types.nullOr (types.listOf types.str);
        };
        "exposeHeadersList" = mkOption {
          description = "ExposeHeadersList defines the Access-Control-Expose-Headers values sent in preflight response.";
          type = types.nullOr (types.listOf types.str);
        };
        "maxAge" = mkOption {
          description = "MaxAge defines the time that a preflight request may be cached.";
          type = types.nullOr types.int;
        };
      };

      config = {
        "addVaryHeader" = mkOverride 1002 null;
        "allowCredentials" = mkOverride 1002 null;
        "allowHeadersList" = mkOverride 1002 null;
        "allowMethodsList" = mkOverride 1002 null;
        "allowOriginListRegex" = mkOverride 1002 null;
        "allowOriginsList" = mkOverride 1002 null;
        "exposeHeadersList" = mkOverride 1002 null;
        "maxAge" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.APIVersionSpecOpenApiSpec" = {

      options = {
        "operationSets" = mkOption {
          description = "OperationSets defines the sets of operations to be referenced for granular filtering in APICatalogItems or ManagedSubscriptions.";
          type = types.nullOr (
            coerceAttrsOfSubmodulesToListByKey "hub.traefik.io.v1alpha1.APIVersionSpecOpenApiSpecOperationSets"
              "name"
              [ ]
          );
          apply = attrsToList;
        };
        "override" = mkOption {
          description = "Override holds data used to override OpenAPI specification.";
          type = types.nullOr (submoduleOf "hub.traefik.io.v1alpha1.APIVersionSpecOpenApiSpecOverride");
        };
        "path" = mkOption {
          description = "Path specifies the endpoint path within the Kubernetes Service where the OpenAPI specification can be obtained.\nThe Service queried is determined by the associated Ingress, IngressRoute, or HTTPRoute resource to which the API is attached.\nIt's important to note that this option is incompatible if the Ingress or IngressRoute specifies multiple backend services.\nThe Path must be accessible via a GET request method and should serve a YAML or JSON document containing the OpenAPI specification.";
          type = types.nullOr types.str;
        };
        "url" = mkOption {
          description = "URL is a Traefik Hub agent accessible URL for obtaining the OpenAPI specification.\nThe URL must be accessible via a GET request method and should serve a YAML or JSON document containing the OpenAPI specification.";
          type = types.nullOr types.str;
        };
        "validateRequestMethodAndPath" = mkOption {
          description = "ValidateRequestMethodAndPath validates that the path and method matches an operation defined in the OpenAPI specification.\nThis option overrides the default behavior configured in the static configuration.";
          type = types.nullOr types.bool;
        };
      };

      config = {
        "operationSets" = mkOverride 1002 null;
        "override" = mkOverride 1002 null;
        "path" = mkOverride 1002 null;
        "url" = mkOverride 1002 null;
        "validateRequestMethodAndPath" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.APIVersionSpecOpenApiSpecOperationSets" = {

      options = {
        "matchers" = mkOption {
          description = "Matchers defines a list of alternative rules for matching OpenAPI operations.";
          type = types.listOf (
            submoduleOf "hub.traefik.io.v1alpha1.APIVersionSpecOpenApiSpecOperationSetsMatchers"
          );
        };
        "name" = mkOption {
          description = "Name is the name of the OperationSet to reference in APICatalogItems or ManagedSubscriptions.";
          type = types.str;
        };
      };

      config = { };

    };
    "hub.traefik.io.v1alpha1.APIVersionSpecOpenApiSpecOperationSetsMatchers" = {

      options = {
        "methods" = mkOption {
          description = "Methods specifies the HTTP methods to be included for selection.";
          type = types.nullOr (types.listOf types.str);
        };
        "path" = mkOption {
          description = "Path specifies the exact path of the operations to select.";
          type = types.nullOr types.str;
        };
        "pathPrefix" = mkOption {
          description = "PathPrefix specifies the path prefix of the operations to select.";
          type = types.nullOr types.str;
        };
        "pathRegex" = mkOption {
          description = "PathRegex specifies a regular expression pattern for matching operations based on their paths.";
          type = types.nullOr types.str;
        };
      };

      config = {
        "methods" = mkOverride 1002 null;
        "path" = mkOverride 1002 null;
        "pathPrefix" = mkOverride 1002 null;
        "pathRegex" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.APIVersionSpecOpenApiSpecOverride" = {

      options = {
        "servers" = mkOption {
          description = "";
          type = types.listOf (
            submoduleOf "hub.traefik.io.v1alpha1.APIVersionSpecOpenApiSpecOverrideServers"
          );
        };
      };

      config = { };

    };
    "hub.traefik.io.v1alpha1.APIVersionSpecOpenApiSpecOverrideServers" = {

      options = {
        "url" = mkOption {
          description = "";
          type = types.str;
        };
      };

      config = { };

    };
    "hub.traefik.io.v1alpha1.APIVersionStatus" = {

      options = {
        "conditions" = mkOption {
          description = "";
          type = types.nullOr (
            types.listOf (submoduleOf "hub.traefik.io.v1alpha1.APIVersionStatusConditions")
          );
        };
        "hash" = mkOption {
          description = "Hash is a hash representing the APIVersion.";
          type = types.nullOr types.str;
        };
        "syncedAt" = mkOption {
          description = "";
          type = types.nullOr types.str;
        };
        "version" = mkOption {
          description = "";
          type = types.nullOr types.str;
        };
      };

      config = {
        "conditions" = mkOverride 1002 null;
        "hash" = mkOverride 1002 null;
        "syncedAt" = mkOverride 1002 null;
        "version" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.APIVersionStatusConditions" = {

      options = {
        "lastTransitionTime" = mkOption {
          description = "lastTransitionTime is the last time the condition transitioned from one status to another.\nThis should be when the underlying condition changed.  If that is not known, then using the time when the API field changed is acceptable.";
          type = types.str;
        };
        "message" = mkOption {
          description = "message is a human readable message indicating details about the transition.\nThis may be an empty string.";
          type = types.str;
        };
        "observedGeneration" = mkOption {
          description = "observedGeneration represents the .metadata.generation that the condition was set based upon.\nFor instance, if .metadata.generation is currently 12, but the .status.conditions[x].observedGeneration is 9, the condition is out of date\nwith respect to the current state of the instance.";
          type = types.nullOr types.int;
        };
        "reason" = mkOption {
          description = "reason contains a programmatic identifier indicating the reason for the condition's last transition.\nProducers of specific condition types may define expected values and meanings for this field,\nand whether the values are considered a guaranteed API.\nThe value should be a CamelCase string.\nThis field may not be empty.";
          type = types.str;
        };
        "status" = mkOption {
          description = "status of the condition, one of True, False, Unknown.";
          type = types.str;
        };
        "type" = mkOption {
          description = "type of condition in CamelCase or in foo.example.com/CamelCase.";
          type = types.str;
        };
      };

      config = {
        "observedGeneration" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.AccessControlPolicy" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object.\nServers should convert recognized schemas to the latest internal value, and\nmay reject unrecognized values.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = types.nullOr types.str;
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents.\nServers may infer this from the endpoint the client submits requests to.\nCannot be updated.\nIn CamelCase.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = types.nullOr types.str;
        };
        "metadata" = mkOption {
          description = "Standard object's metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = types.nullOr (globalSubmoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta");
        };
        "spec" = mkOption {
          description = "AccessControlPolicySpec configures an access control policy.";
          type = types.nullOr (submoduleOf "hub.traefik.io.v1alpha1.AccessControlPolicySpec");
        };
        "status" = mkOption {
          description = "The current status of this access control policy.";
          type = types.nullOr (submoduleOf "hub.traefik.io.v1alpha1.AccessControlPolicyStatus");
        };
      };

      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "spec" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.AccessControlPolicySpec" = {

      options = {
        "apiKey" = mkOption {
          description = "AccessControlPolicyAPIKey configure an APIKey control policy.";
          type = types.nullOr (submoduleOf "hub.traefik.io.v1alpha1.AccessControlPolicySpecApiKey");
        };
        "basicAuth" = mkOption {
          description = "AccessControlPolicyBasicAuth holds the HTTP basic authentication configuration.";
          type = types.nullOr (submoduleOf "hub.traefik.io.v1alpha1.AccessControlPolicySpecBasicAuth");
        };
        "jwt" = mkOption {
          description = "AccessControlPolicyJWT configures a JWT access control policy.";
          type = types.nullOr (submoduleOf "hub.traefik.io.v1alpha1.AccessControlPolicySpecJwt");
        };
        "oAuthIntro" = mkOption {
          description = "AccessControlOAuthIntro configures an OAuth 2.0 Token Introspection access control policy.";
          type = types.nullOr (submoduleOf "hub.traefik.io.v1alpha1.AccessControlPolicySpecOAuthIntro");
        };
        "oidc" = mkOption {
          description = "AccessControlPolicyOIDC holds the OIDC authentication configuration.";
          type = types.nullOr (submoduleOf "hub.traefik.io.v1alpha1.AccessControlPolicySpecOidc");
        };
        "oidcGoogle" = mkOption {
          description = "AccessControlPolicyOIDCGoogle holds the Google OIDC authentication configuration.";
          type = types.nullOr (submoduleOf "hub.traefik.io.v1alpha1.AccessControlPolicySpecOidcGoogle");
        };
      };

      config = {
        "apiKey" = mkOverride 1002 null;
        "basicAuth" = mkOverride 1002 null;
        "jwt" = mkOverride 1002 null;
        "oAuthIntro" = mkOverride 1002 null;
        "oidc" = mkOverride 1002 null;
        "oidcGoogle" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.AccessControlPolicySpecApiKey" = {

      options = {
        "forwardHeaders" = mkOption {
          description = "ForwardHeaders instructs the middleware to forward key metadata as header values upon successful authentication.";
          type = types.nullOr (types.attrsOf types.str);
        };
        "keySource" = mkOption {
          description = "KeySource defines how to extract API keys from requests.";
          type = submoduleOf "hub.traefik.io.v1alpha1.AccessControlPolicySpecApiKeyKeySource";
        };
        "keys" = mkOption {
          description = "Keys define the set of authorized keys to access a protected resource.";
          type = types.nullOr (
            types.listOf (submoduleOf "hub.traefik.io.v1alpha1.AccessControlPolicySpecApiKeyKeys")
          );
        };
      };

      config = {
        "forwardHeaders" = mkOverride 1002 null;
        "keys" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.AccessControlPolicySpecApiKeyKeySource" = {

      options = {
        "cookie" = mkOption {
          description = "Cookie is the name of a cookie.";
          type = types.nullOr types.str;
        };
        "header" = mkOption {
          description = "Header is the name of a header.";
          type = types.nullOr types.str;
        };
        "headerAuthScheme" = mkOption {
          description = "HeaderAuthScheme sets an optional auth scheme when Header is set to \"Authorization\".\nIf set, this scheme is removed from the token, and all requests not including it are dropped.";
          type = types.nullOr types.str;
        };
        "query" = mkOption {
          description = "Query is the name of a query parameter.";
          type = types.nullOr types.str;
        };
      };

      config = {
        "cookie" = mkOverride 1002 null;
        "header" = mkOverride 1002 null;
        "headerAuthScheme" = mkOverride 1002 null;
        "query" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.AccessControlPolicySpecApiKeyKeys" = {

      options = {
        "id" = mkOption {
          description = "ID is the unique identifier of the key.";
          type = types.str;
        };
        "metadata" = mkOption {
          description = "Metadata holds arbitrary metadata for this key, can be used by ForwardHeaders.";
          type = types.nullOr (types.attrsOf types.str);
        };
        "value" = mkOption {
          description = "Value is the SHAKE-256 hash (using 64 bytes) of the API key.";
          type = types.str;
        };
      };

      config = {
        "metadata" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.AccessControlPolicySpecBasicAuth" = {

      options = {
        "forwardUsernameHeader" = mkOption {
          description = "";
          type = types.nullOr types.str;
        };
        "realm" = mkOption {
          description = "";
          type = types.nullOr types.str;
        };
        "stripAuthorizationHeader" = mkOption {
          description = "";
          type = types.nullOr types.bool;
        };
        "users" = mkOption {
          description = "";
          type = types.nullOr (types.listOf types.str);
        };
      };

      config = {
        "forwardUsernameHeader" = mkOverride 1002 null;
        "realm" = mkOverride 1002 null;
        "stripAuthorizationHeader" = mkOverride 1002 null;
        "users" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.AccessControlPolicySpecJwt" = {

      options = {
        "claims" = mkOption {
          description = "";
          type = types.nullOr types.str;
        };
        "forwardHeaders" = mkOption {
          description = "";
          type = types.nullOr (types.attrsOf types.str);
        };
        "jwksFile" = mkOption {
          description = "";
          type = types.nullOr types.str;
        };
        "jwksUrl" = mkOption {
          description = "";
          type = types.nullOr types.str;
        };
        "publicKey" = mkOption {
          description = "";
          type = types.nullOr types.str;
        };
        "signingSecret" = mkOption {
          description = "";
          type = types.nullOr types.str;
        };
        "signingSecretBase64Encoded" = mkOption {
          description = "";
          type = types.nullOr types.bool;
        };
        "stripAuthorizationHeader" = mkOption {
          description = "";
          type = types.nullOr types.bool;
        };
        "tokenQueryKey" = mkOption {
          description = "";
          type = types.nullOr types.str;
        };
      };

      config = {
        "claims" = mkOverride 1002 null;
        "forwardHeaders" = mkOverride 1002 null;
        "jwksFile" = mkOverride 1002 null;
        "jwksUrl" = mkOverride 1002 null;
        "publicKey" = mkOverride 1002 null;
        "signingSecret" = mkOverride 1002 null;
        "signingSecretBase64Encoded" = mkOverride 1002 null;
        "stripAuthorizationHeader" = mkOverride 1002 null;
        "tokenQueryKey" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.AccessControlPolicySpecOAuthIntro" = {

      options = {
        "claims" = mkOption {
          description = "";
          type = types.nullOr types.str;
        };
        "clientConfig" = mkOption {
          description = "AccessControlOAuthIntroClientConfig configures the OAuth 2.0 client for issuing token introspection requests.";
          type = submoduleOf "hub.traefik.io.v1alpha1.AccessControlPolicySpecOAuthIntroClientConfig";
        };
        "forwardHeaders" = mkOption {
          description = "";
          type = types.nullOr (types.attrsOf types.str);
        };
        "tokenSource" = mkOption {
          description = "TokenSource describes how to extract tokens from HTTP requests.\nIf multiple sources are set, the order is the following: header > query > cookie.";
          type = submoduleOf "hub.traefik.io.v1alpha1.AccessControlPolicySpecOAuthIntroTokenSource";
        };
      };

      config = {
        "claims" = mkOverride 1002 null;
        "forwardHeaders" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.AccessControlPolicySpecOAuthIntroClientConfig" = {

      options = {
        "headers" = mkOption {
          description = "Headers to set when sending requests to the Authorization Server.";
          type = types.nullOr (types.attrsOf types.str);
        };
        "maxRetries" = mkOption {
          description = "MaxRetries defines the number of retries for introspection requests.";
          type = types.nullOr types.int;
        };
        "timeoutSeconds" = mkOption {
          description = "TimeoutSeconds configures the maximum amount of seconds to wait before giving up on requests.";
          type = types.nullOr types.int;
        };
        "tls" = mkOption {
          description = "TLS configures TLS communication with the Authorization Server.";
          type = types.nullOr (
            submoduleOf "hub.traefik.io.v1alpha1.AccessControlPolicySpecOAuthIntroClientConfigTls"
          );
        };
        "tokenTypeHint" = mkOption {
          description = "TokenTypeHint is a hint to pass to the Authorization Server.\nSee https://tools.ietf.org/html/rfc7662#section-2.1 for more information.";
          type = types.nullOr types.str;
        };
        "url" = mkOption {
          description = "URL of the Authorization Server.";
          type = types.str;
        };
      };

      config = {
        "headers" = mkOverride 1002 null;
        "maxRetries" = mkOverride 1002 null;
        "timeoutSeconds" = mkOverride 1002 null;
        "tls" = mkOverride 1002 null;
        "tokenTypeHint" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.AccessControlPolicySpecOAuthIntroClientConfigTls" = {

      options = {
        "ca" = mkOption {
          description = "CA sets the CA bundle used to sign the Authorization Server certificate.";
          type = types.nullOr types.str;
        };
        "insecureSkipVerify" = mkOption {
          description = "InsecureSkipVerify skips the Authorization Server certificate validation.\nFor testing purposes only, do not use in production.";
          type = types.nullOr types.bool;
        };
      };

      config = {
        "ca" = mkOverride 1002 null;
        "insecureSkipVerify" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.AccessControlPolicySpecOAuthIntroTokenSource" = {

      options = {
        "cookie" = mkOption {
          description = "Cookie is the name of a cookie.";
          type = types.nullOr types.str;
        };
        "header" = mkOption {
          description = "Header is the name of a header.";
          type = types.nullOr types.str;
        };
        "headerAuthScheme" = mkOption {
          description = "HeaderAuthScheme sets an optional auth scheme when Header is set to \"Authorization\".\nIf set, this scheme is removed from the token, and all requests not including it are dropped.";
          type = types.nullOr types.str;
        };
        "query" = mkOption {
          description = "Query is the name of a query parameter.";
          type = types.nullOr types.str;
        };
      };

      config = {
        "cookie" = mkOverride 1002 null;
        "header" = mkOverride 1002 null;
        "headerAuthScheme" = mkOverride 1002 null;
        "query" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.AccessControlPolicySpecOidc" = {

      options = {
        "authParams" = mkOption {
          description = "";
          type = types.nullOr (types.attrsOf types.str);
        };
        "claims" = mkOption {
          description = "";
          type = types.nullOr types.str;
        };
        "clientId" = mkOption {
          description = "";
          type = types.nullOr types.str;
        };
        "disableAuthRedirectionPaths" = mkOption {
          description = "";
          type = types.nullOr (types.listOf types.str);
        };
        "forwardHeaders" = mkOption {
          description = "";
          type = types.nullOr (types.attrsOf types.str);
        };
        "issuer" = mkOption {
          description = "";
          type = types.nullOr types.str;
        };
        "logoutUrl" = mkOption {
          description = "";
          type = types.nullOr types.str;
        };
        "redirectUrl" = mkOption {
          description = "";
          type = types.nullOr types.str;
        };
        "scopes" = mkOption {
          description = "";
          type = types.nullOr (types.listOf types.str);
        };
        "secret" = mkOption {
          description = "SecretReference represents a Secret Reference. It has enough information to retrieve secret\nin any namespace";
          type = types.nullOr (submoduleOf "hub.traefik.io.v1alpha1.AccessControlPolicySpecOidcSecret");
        };
        "session" = mkOption {
          description = "Session holds session configuration.";
          type = types.nullOr (submoduleOf "hub.traefik.io.v1alpha1.AccessControlPolicySpecOidcSession");
        };
        "stateCookie" = mkOption {
          description = "StateCookie holds state cookie configuration.";
          type = types.nullOr (submoduleOf "hub.traefik.io.v1alpha1.AccessControlPolicySpecOidcStateCookie");
        };
      };

      config = {
        "authParams" = mkOverride 1002 null;
        "claims" = mkOverride 1002 null;
        "clientId" = mkOverride 1002 null;
        "disableAuthRedirectionPaths" = mkOverride 1002 null;
        "forwardHeaders" = mkOverride 1002 null;
        "issuer" = mkOverride 1002 null;
        "logoutUrl" = mkOverride 1002 null;
        "redirectUrl" = mkOverride 1002 null;
        "scopes" = mkOverride 1002 null;
        "secret" = mkOverride 1002 null;
        "session" = mkOverride 1002 null;
        "stateCookie" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.AccessControlPolicySpecOidcGoogle" = {

      options = {
        "authParams" = mkOption {
          description = "";
          type = types.nullOr (types.attrsOf types.str);
        };
        "clientId" = mkOption {
          description = "";
          type = types.nullOr types.str;
        };
        "emails" = mkOption {
          description = "Emails are the allowed emails to connect.";
          type = types.nullOr (types.listOf types.str);
        };
        "forwardHeaders" = mkOption {
          description = "";
          type = types.nullOr (types.attrsOf types.str);
        };
        "logoutUrl" = mkOption {
          description = "";
          type = types.nullOr types.str;
        };
        "redirectUrl" = mkOption {
          description = "";
          type = types.nullOr types.str;
        };
        "secret" = mkOption {
          description = "SecretReference represents a Secret Reference. It has enough information to retrieve secret\nin any namespace";
          type = types.nullOr (submoduleOf "hub.traefik.io.v1alpha1.AccessControlPolicySpecOidcGoogleSecret");
        };
        "session" = mkOption {
          description = "Session holds session configuration.";
          type = types.nullOr (
            submoduleOf "hub.traefik.io.v1alpha1.AccessControlPolicySpecOidcGoogleSession"
          );
        };
        "stateCookie" = mkOption {
          description = "StateCookie holds state cookie configuration.";
          type = types.nullOr (
            submoduleOf "hub.traefik.io.v1alpha1.AccessControlPolicySpecOidcGoogleStateCookie"
          );
        };
      };

      config = {
        "authParams" = mkOverride 1002 null;
        "clientId" = mkOverride 1002 null;
        "emails" = mkOverride 1002 null;
        "forwardHeaders" = mkOverride 1002 null;
        "logoutUrl" = mkOverride 1002 null;
        "redirectUrl" = mkOverride 1002 null;
        "secret" = mkOverride 1002 null;
        "session" = mkOverride 1002 null;
        "stateCookie" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.AccessControlPolicySpecOidcGoogleSecret" = {

      options = {
        "name" = mkOption {
          description = "name is unique within a namespace to reference a secret resource.";
          type = types.nullOr types.str;
        };
        "namespace" = mkOption {
          description = "namespace defines the space within which the secret name must be unique.";
          type = types.nullOr types.str;
        };
      };

      config = {
        "name" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.AccessControlPolicySpecOidcGoogleSession" = {

      options = {
        "domain" = mkOption {
          description = "";
          type = types.nullOr types.str;
        };
        "path" = mkOption {
          description = "";
          type = types.nullOr types.str;
        };
        "refresh" = mkOption {
          description = "";
          type = types.nullOr types.bool;
        };
        "sameSite" = mkOption {
          description = "";
          type = types.nullOr types.str;
        };
        "secure" = mkOption {
          description = "";
          type = types.nullOr types.bool;
        };
      };

      config = {
        "domain" = mkOverride 1002 null;
        "path" = mkOverride 1002 null;
        "refresh" = mkOverride 1002 null;
        "sameSite" = mkOverride 1002 null;
        "secure" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.AccessControlPolicySpecOidcGoogleStateCookie" = {

      options = {
        "domain" = mkOption {
          description = "";
          type = types.nullOr types.str;
        };
        "path" = mkOption {
          description = "";
          type = types.nullOr types.str;
        };
        "sameSite" = mkOption {
          description = "";
          type = types.nullOr types.str;
        };
        "secure" = mkOption {
          description = "";
          type = types.nullOr types.bool;
        };
      };

      config = {
        "domain" = mkOverride 1002 null;
        "path" = mkOverride 1002 null;
        "sameSite" = mkOverride 1002 null;
        "secure" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.AccessControlPolicySpecOidcSecret" = {

      options = {
        "name" = mkOption {
          description = "name is unique within a namespace to reference a secret resource.";
          type = types.nullOr types.str;
        };
        "namespace" = mkOption {
          description = "namespace defines the space within which the secret name must be unique.";
          type = types.nullOr types.str;
        };
      };

      config = {
        "name" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.AccessControlPolicySpecOidcSession" = {

      options = {
        "domain" = mkOption {
          description = "";
          type = types.nullOr types.str;
        };
        "path" = mkOption {
          description = "";
          type = types.nullOr types.str;
        };
        "refresh" = mkOption {
          description = "";
          type = types.nullOr types.bool;
        };
        "sameSite" = mkOption {
          description = "";
          type = types.nullOr types.str;
        };
        "secure" = mkOption {
          description = "";
          type = types.nullOr types.bool;
        };
      };

      config = {
        "domain" = mkOverride 1002 null;
        "path" = mkOverride 1002 null;
        "refresh" = mkOverride 1002 null;
        "sameSite" = mkOverride 1002 null;
        "secure" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.AccessControlPolicySpecOidcStateCookie" = {

      options = {
        "domain" = mkOption {
          description = "";
          type = types.nullOr types.str;
        };
        "path" = mkOption {
          description = "";
          type = types.nullOr types.str;
        };
        "sameSite" = mkOption {
          description = "";
          type = types.nullOr types.str;
        };
        "secure" = mkOption {
          description = "";
          type = types.nullOr types.bool;
        };
      };

      config = {
        "domain" = mkOverride 1002 null;
        "path" = mkOverride 1002 null;
        "sameSite" = mkOverride 1002 null;
        "secure" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.AccessControlPolicyStatus" = {

      options = {
        "specHash" = mkOption {
          description = "";
          type = types.nullOr types.str;
        };
        "syncedAt" = mkOption {
          description = "";
          type = types.nullOr types.str;
        };
        "version" = mkOption {
          description = "";
          type = types.nullOr types.str;
        };
      };

      config = {
        "specHash" = mkOverride 1002 null;
        "syncedAt" = mkOverride 1002 null;
        "version" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.ManagedApplication" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object.\nServers should convert recognized schemas to the latest internal value, and\nmay reject unrecognized values.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = types.nullOr types.str;
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents.\nServers may infer this from the endpoint the client submits requests to.\nCannot be updated.\nIn CamelCase.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = types.nullOr types.str;
        };
        "metadata" = mkOption {
          description = "Standard object's metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = types.nullOr (globalSubmoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta");
        };
        "spec" = mkOption {
          description = "ManagedApplicationSpec describes the ManagedApplication.";
          type = types.nullOr (submoduleOf "hub.traefik.io.v1alpha1.ManagedApplicationSpec");
        };
        "status" = mkOption {
          description = "The current status of this ManagedApplication.";
          type = types.nullOr (submoduleOf "hub.traefik.io.v1alpha1.ManagedApplicationStatus");
        };
      };

      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "spec" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.ManagedApplicationSpec" = {

      options = {
        "apiKeys" = mkOption {
          description = "APIKeys references the API keys used to authenticate the application when calling APIs.";
          type = types.nullOr (
            types.listOf (submoduleOf "hub.traefik.io.v1alpha1.ManagedApplicationSpecApiKeys")
          );
        };
        "appId" = mkOption {
          description = "AppID is the identifier of the ManagedApplication.\nIt should be unique.";
          type = types.str;
        };
        "notes" = mkOption {
          description = "Notes contains notes about application.";
          type = types.nullOr types.str;
        };
        "owner" = mkOption {
          description = "Owner represents the owner of the ManagedApplication.\nIt should be:\n- `sub` when using OIDC\n- `externalID` when using external IDP";
          type = types.str;
        };
      };

      config = {
        "apiKeys" = mkOverride 1002 null;
        "notes" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.ManagedApplicationSpecApiKeys" = {

      options = {
        "secretName" = mkOption {
          description = "SecretName references the name of the secret containing the API key.";
          type = types.nullOr types.str;
        };
        "suspended" = mkOption {
          description = "";
          type = types.nullOr types.bool;
        };
        "title" = mkOption {
          description = "";
          type = types.nullOr types.str;
        };
        "value" = mkOption {
          description = "Value is the API key value.";
          type = types.nullOr types.str;
        };
      };

      config = {
        "secretName" = mkOverride 1002 null;
        "suspended" = mkOverride 1002 null;
        "title" = mkOverride 1002 null;
        "value" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.ManagedApplicationStatus" = {

      options = {
        "apiKeyVersions" = mkOption {
          description = "";
          type = types.nullOr (types.attrsOf types.str);
        };
        "conditions" = mkOption {
          description = "";
          type = types.nullOr (
            types.listOf (submoduleOf "hub.traefik.io.v1alpha1.ManagedApplicationStatusConditions")
          );
        };
        "hash" = mkOption {
          description = "Hash is a hash representing the ManagedApplication.";
          type = types.nullOr types.str;
        };
        "syncedAt" = mkOption {
          description = "";
          type = types.nullOr types.str;
        };
        "version" = mkOption {
          description = "";
          type = types.nullOr types.str;
        };
      };

      config = {
        "apiKeyVersions" = mkOverride 1002 null;
        "conditions" = mkOverride 1002 null;
        "hash" = mkOverride 1002 null;
        "syncedAt" = mkOverride 1002 null;
        "version" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.ManagedApplicationStatusConditions" = {

      options = {
        "lastTransitionTime" = mkOption {
          description = "lastTransitionTime is the last time the condition transitioned from one status to another.\nThis should be when the underlying condition changed.  If that is not known, then using the time when the API field changed is acceptable.";
          type = types.str;
        };
        "message" = mkOption {
          description = "message is a human readable message indicating details about the transition.\nThis may be an empty string.";
          type = types.str;
        };
        "observedGeneration" = mkOption {
          description = "observedGeneration represents the .metadata.generation that the condition was set based upon.\nFor instance, if .metadata.generation is currently 12, but the .status.conditions[x].observedGeneration is 9, the condition is out of date\nwith respect to the current state of the instance.";
          type = types.nullOr types.int;
        };
        "reason" = mkOption {
          description = "reason contains a programmatic identifier indicating the reason for the condition's last transition.\nProducers of specific condition types may define expected values and meanings for this field,\nand whether the values are considered a guaranteed API.\nThe value should be a CamelCase string.\nThis field may not be empty.";
          type = types.str;
        };
        "status" = mkOption {
          description = "status of the condition, one of True, False, Unknown.";
          type = types.str;
        };
        "type" = mkOption {
          description = "type of condition in CamelCase or in foo.example.com/CamelCase.";
          type = types.str;
        };
      };

      config = {
        "observedGeneration" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.ManagedSubscription" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object.\nServers should convert recognized schemas to the latest internal value, and\nmay reject unrecognized values.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = types.nullOr types.str;
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents.\nServers may infer this from the endpoint the client submits requests to.\nCannot be updated.\nIn CamelCase.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = types.nullOr types.str;
        };
        "metadata" = mkOption {
          description = "Standard object's metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = types.nullOr (globalSubmoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta");
        };
        "spec" = mkOption {
          description = "The desired behavior of this ManagedSubscription.";
          type = types.nullOr (submoduleOf "hub.traefik.io.v1alpha1.ManagedSubscriptionSpec");
        };
        "status" = mkOption {
          description = "The current status of this ManagedSubscription.";
          type = types.nullOr (submoduleOf "hub.traefik.io.v1alpha1.ManagedSubscriptionStatus");
        };
      };

      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "spec" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.ManagedSubscriptionSpec" = {

      options = {
        "apiBundles" = mkOption {
          description = "APIBundles defines a set of APIBundle that will be accessible.\nMultiple ManagedSubscriptions can select the same APIBundles.";
          type = types.nullOr (
            coerceAttrsOfSubmodulesToListByKey "hub.traefik.io.v1alpha1.ManagedSubscriptionSpecApiBundles"
              "name"
              [ ]
          );
          apply = attrsToList;
        };
        "apiPlan" = mkOption {
          description = "APIPlan defines which APIPlan will be used.";
          type = submoduleOf "hub.traefik.io.v1alpha1.ManagedSubscriptionSpecApiPlan";
        };
        "apiSelector" = mkOption {
          description = "APISelector selects the APIs that will be accessible.\nMultiple ManagedSubscriptions can select the same set of APIs.\nThis field is optional and follows standard label selector semantics.\nAn empty APISelector matches any API.";
          type = types.nullOr (submoduleOf "hub.traefik.io.v1alpha1.ManagedSubscriptionSpecApiSelector");
        };
        "apis" = mkOption {
          description = "APIs defines a set of APIs that will be accessible.\nMultiple ManagedSubscriptions can select the same APIs.\nWhen combined with APISelector, this set of APIs is appended to the matching APIs.";
          type = types.nullOr (
            coerceAttrsOfSubmodulesToListByKey "hub.traefik.io.v1alpha1.ManagedSubscriptionSpecApis" "name" [ ]
          );
          apply = attrsToList;
        };
        "applications" = mkOption {
          description = "Applications references the Applications that will gain access to the specified APIs.\nMultiple ManagedSubscriptions can select the same AppID.\nDeprecated: Use ManagedApplications instead.";
          type = types.nullOr (
            types.listOf (submoduleOf "hub.traefik.io.v1alpha1.ManagedSubscriptionSpecApplications")
          );
        };
        "claims" = mkOption {
          description = "Claims specifies an expression that validate claims in order to authorize the request.";
          type = types.nullOr types.str;
        };
        "managedApplications" = mkOption {
          description = "ManagedApplications references the ManagedApplications that will gain access to the specified APIs.\nMultiple ManagedSubscriptions can select the same ManagedApplication.";
          type = types.nullOr (
            coerceAttrsOfSubmodulesToListByKey
              "hub.traefik.io.v1alpha1.ManagedSubscriptionSpecManagedApplications"
              "name"
              [ ]
          );
          apply = attrsToList;
        };
        "operationFilter" = mkOption {
          description = "OperationFilter specifies the allowed operations on APIs and APIVersions.\nIf not set, all operations are available.\nAn empty OperationFilter prohibits all operations.";
          type = types.nullOr (submoduleOf "hub.traefik.io.v1alpha1.ManagedSubscriptionSpecOperationFilter");
        };
        "weight" = mkOption {
          description = "Weight specifies the evaluation order of the APIPlan.\nWhen multiple ManagedSubscriptions targets the same API and Application with different APIPlan,\nthe APIPlan with the highest weight will be enforced. If weights are equal, alphabetical order is used.";
          type = types.nullOr types.int;
        };
      };

      config = {
        "apiBundles" = mkOverride 1002 null;
        "apiSelector" = mkOverride 1002 null;
        "apis" = mkOverride 1002 null;
        "applications" = mkOverride 1002 null;
        "claims" = mkOverride 1002 null;
        "managedApplications" = mkOverride 1002 null;
        "operationFilter" = mkOverride 1002 null;
        "weight" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.ManagedSubscriptionSpecApiBundles" = {

      options = {
        "name" = mkOption {
          description = "Name of the APIBundle.";
          type = types.str;
        };
      };

      config = { };

    };
    "hub.traefik.io.v1alpha1.ManagedSubscriptionSpecApiPlan" = {

      options = {
        "name" = mkOption {
          description = "Name of the APIPlan.";
          type = types.str;
        };
      };

      config = { };

    };
    "hub.traefik.io.v1alpha1.ManagedSubscriptionSpecApiSelector" = {

      options = {
        "matchExpressions" = mkOption {
          description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
          type = types.nullOr (
            types.listOf (
              submoduleOf "hub.traefik.io.v1alpha1.ManagedSubscriptionSpecApiSelectorMatchExpressions"
            )
          );
        };
        "matchLabels" = mkOption {
          description = "matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels\nmap is equivalent to an element of matchExpressions, whose key field is \"key\", the\noperator is \"In\", and the values array contains only \"value\". The requirements are ANDed.";
          type = types.nullOr (types.attrsOf types.str);
        };
      };

      config = {
        "matchExpressions" = mkOverride 1002 null;
        "matchLabels" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.ManagedSubscriptionSpecApiSelectorMatchExpressions" = {

      options = {
        "key" = mkOption {
          description = "key is the label key that the selector applies to.";
          type = types.str;
        };
        "operator" = mkOption {
          description = "operator represents a key's relationship to a set of values.\nValid operators are In, NotIn, Exists and DoesNotExist.";
          type = types.str;
        };
        "values" = mkOption {
          description = "values is an array of string values. If the operator is In or NotIn,\nthe values array must be non-empty. If the operator is Exists or DoesNotExist,\nthe values array must be empty. This array is replaced during a strategic\nmerge patch.";
          type = types.nullOr (types.listOf types.str);
        };
      };

      config = {
        "values" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.ManagedSubscriptionSpecApis" = {

      options = {
        "name" = mkOption {
          description = "Name of the API.";
          type = types.str;
        };
      };

      config = { };

    };
    "hub.traefik.io.v1alpha1.ManagedSubscriptionSpecApplications" = {

      options = {
        "appId" = mkOption {
          description = "AppID is the public identifier of the application.\nIn the case of OIDC, it corresponds to the clientId.";
          type = types.str;
        };
      };

      config = { };

    };
    "hub.traefik.io.v1alpha1.ManagedSubscriptionSpecManagedApplications" = {

      options = {
        "name" = mkOption {
          description = "Name is the name of the ManagedApplication.";
          type = types.str;
        };
      };

      config = { };

    };
    "hub.traefik.io.v1alpha1.ManagedSubscriptionSpecOperationFilter" = {

      options = {
        "include" = mkOption {
          description = "Include defines the names of OperationSets that will be accessible.";
          type = types.nullOr (types.listOf types.str);
        };
      };

      config = {
        "include" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.ManagedSubscriptionStatus" = {

      options = {
        "conditions" = mkOption {
          description = "Conditions is the list of status conditions.";
          type = types.nullOr (
            types.listOf (submoduleOf "hub.traefik.io.v1alpha1.ManagedSubscriptionStatusConditions")
          );
        };
        "hash" = mkOption {
          description = "Hash is a hash representing the ManagedSubscription.";
          type = types.nullOr types.str;
        };
        "resolvedApis" = mkOption {
          description = "ResolvedAPIs is the list of APIs that were successfully resolved.";
          type = types.nullOr (
            coerceAttrsOfSubmodulesToListByKey "hub.traefik.io.v1alpha1.ManagedSubscriptionStatusResolvedApis"
              "name"
              [ ]
          );
          apply = attrsToList;
        };
        "syncedAt" = mkOption {
          description = "";
          type = types.nullOr types.str;
        };
        "unresolvedApis" = mkOption {
          description = "UnresolvedAPIs is the list of APIs that could not be resolved.";
          type = types.nullOr (
            coerceAttrsOfSubmodulesToListByKey "hub.traefik.io.v1alpha1.ManagedSubscriptionStatusUnresolvedApis"
              "name"
              [ ]
          );
          apply = attrsToList;
        };
        "version" = mkOption {
          description = "";
          type = types.nullOr types.str;
        };
      };

      config = {
        "conditions" = mkOverride 1002 null;
        "hash" = mkOverride 1002 null;
        "resolvedApis" = mkOverride 1002 null;
        "syncedAt" = mkOverride 1002 null;
        "unresolvedApis" = mkOverride 1002 null;
        "version" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.ManagedSubscriptionStatusConditions" = {

      options = {
        "lastTransitionTime" = mkOption {
          description = "lastTransitionTime is the last time the condition transitioned from one status to another.\nThis should be when the underlying condition changed.  If that is not known, then using the time when the API field changed is acceptable.";
          type = types.str;
        };
        "message" = mkOption {
          description = "message is a human readable message indicating details about the transition.\nThis may be an empty string.";
          type = types.str;
        };
        "observedGeneration" = mkOption {
          description = "observedGeneration represents the .metadata.generation that the condition was set based upon.\nFor instance, if .metadata.generation is currently 12, but the .status.conditions[x].observedGeneration is 9, the condition is out of date\nwith respect to the current state of the instance.";
          type = types.nullOr types.int;
        };
        "reason" = mkOption {
          description = "reason contains a programmatic identifier indicating the reason for the condition's last transition.\nProducers of specific condition types may define expected values and meanings for this field,\nand whether the values are considered a guaranteed API.\nThe value should be a CamelCase string.\nThis field may not be empty.";
          type = types.str;
        };
        "status" = mkOption {
          description = "status of the condition, one of True, False, Unknown.";
          type = types.str;
        };
        "type" = mkOption {
          description = "type of condition in CamelCase or in foo.example.com/CamelCase.";
          type = types.str;
        };
      };

      config = {
        "observedGeneration" = mkOverride 1002 null;
      };

    };
    "hub.traefik.io.v1alpha1.ManagedSubscriptionStatusResolvedApis" = {

      options = {
        "name" = mkOption {
          description = "Name of the API.";
          type = types.str;
        };
      };

      config = { };

    };
    "hub.traefik.io.v1alpha1.ManagedSubscriptionStatusUnresolvedApis" = {

      options = {
        "name" = mkOption {
          description = "Name of the API.";
          type = types.str;
        };
      };

      config = { };

    };
    "traefik.io.v1alpha1.IngressRoute" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object.\nServers should convert recognized schemas to the latest internal value, and\nmay reject unrecognized values.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = types.nullOr types.str;
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents.\nServers may infer this from the endpoint the client submits requests to.\nCannot be updated.\nIn CamelCase.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = types.nullOr types.str;
        };
        "metadata" = mkOption {
          description = "Standard object's metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = globalSubmoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta";
        };
        "spec" = mkOption {
          description = "IngressRouteSpec defines the desired state of IngressRoute.";
          type = submoduleOf "traefik.io.v1alpha1.IngressRouteSpec";
        };
      };

      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.IngressRouteSpec" = {

      options = {
        "entryPoints" = mkOption {
          description = "EntryPoints defines the list of entry point names to bind to.\nEntry points have to be configured in the static configuration.\nMore info: https://doc.traefik.io/traefik/v3.6/reference/install-configuration/entrypoints/\nDefault: all.";
          type = types.nullOr (types.listOf types.str);
        };
        "parentRefs" = mkOption {
          description = "ParentRefs defines references to parent IngressRoute resources for multi-layer routing.\nWhen set, this IngressRoute's routers will be children of the referenced parent IngressRoute's routers.\nMore info: https://doc.traefik.io/traefik/v3.6/routing/routers/#parentrefs";
          type = types.nullOr (
            coerceAttrsOfSubmodulesToListByKey "traefik.io.v1alpha1.IngressRouteSpecParentRefs" "name" [ ]
          );
          apply = attrsToList;
        };
        "routes" = mkOption {
          description = "Routes defines the list of routes.";
          type = types.listOf (submoduleOf "traefik.io.v1alpha1.IngressRouteSpecRoutes");
        };
        "tls" = mkOption {
          description = "TLS defines the TLS configuration.\nMore info: https://doc.traefik.io/traefik/v3.6/reference/routing-configuration/http/routing/router/#tls";
          type = types.nullOr (submoduleOf "traefik.io.v1alpha1.IngressRouteSpecTls");
        };
      };

      config = {
        "entryPoints" = mkOverride 1002 null;
        "parentRefs" = mkOverride 1002 null;
        "tls" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.IngressRouteSpecParentRefs" = {

      options = {
        "name" = mkOption {
          description = "Name defines the name of the referenced IngressRoute resource.";
          type = types.str;
        };
        "namespace" = mkOption {
          description = "Namespace defines the namespace of the referenced IngressRoute resource.";
          type = types.nullOr types.str;
        };
      };

      config = {
        "namespace" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.IngressRouteSpecRoutes" = {

      options = {
        "kind" = mkOption {
          description = "Kind defines the kind of the route.\nRule is the only supported kind.\nIf not defined, defaults to Rule.";
          type = types.nullOr types.str;
        };
        "match" = mkOption {
          description = "Match defines the router's rule.\nMore info: https://doc.traefik.io/traefik/v3.6/reference/routing-configuration/http/routing/rules-and-priority/";
          type = types.str;
        };
        "middlewares" = mkOption {
          description = "Middlewares defines the list of references to Middleware resources.\nMore info: https://doc.traefik.io/traefik/v3.6/reference/routing-configuration/kubernetes/crd/http/middleware/";
          type = types.nullOr (
            coerceAttrsOfSubmodulesToListByKey "traefik.io.v1alpha1.IngressRouteSpecRoutesMiddlewares" "name"
              [ ]
          );
          apply = attrsToList;
        };
        "observability" = mkOption {
          description = "Observability defines the observability configuration for a router.\nMore info: https://doc.traefik.io/traefik/v3.6/reference/routing-configuration/http/routing/observability/";
          type = types.nullOr (submoduleOf "traefik.io.v1alpha1.IngressRouteSpecRoutesObservability");
        };
        "priority" = mkOption {
          description = "Priority defines the router's priority.\nMore info: https://doc.traefik.io/traefik/v3.6/reference/routing-configuration/http/routing/rules-and-priority/#priority";
          type = types.nullOr types.int;
        };
        "services" = mkOption {
          description = "Services defines the list of Service.\nIt can contain any combination of TraefikService and/or reference to a Kubernetes Service.";
          type = types.nullOr (
            coerceAttrsOfSubmodulesToListByKey "traefik.io.v1alpha1.IngressRouteSpecRoutesServices" "name" [ ]
          );
          apply = attrsToList;
        };
        "syntax" = mkOption {
          description = "Syntax defines the router's rule syntax.\nMore info: https://doc.traefik.io/traefik/v3.6/reference/routing-configuration/http/routing/rules-and-priority/#rulesyntax\n\nDeprecated: Please do not use this field and rewrite the router rules to use the v3 syntax.";
          type = types.nullOr types.str;
        };
      };

      config = {
        "kind" = mkOverride 1002 null;
        "middlewares" = mkOverride 1002 null;
        "observability" = mkOverride 1002 null;
        "priority" = mkOverride 1002 null;
        "services" = mkOverride 1002 null;
        "syntax" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.IngressRouteSpecRoutesMiddlewares" = {

      options = {
        "name" = mkOption {
          description = "Name defines the name of the referenced Middleware resource.";
          type = types.str;
        };
        "namespace" = mkOption {
          description = "Namespace defines the namespace of the referenced Middleware resource.";
          type = types.nullOr types.str;
        };
      };

      config = {
        "namespace" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.IngressRouteSpecRoutesObservability" = {

      options = {
        "accessLogs" = mkOption {
          description = "AccessLogs enables access logs for this router.";
          type = types.nullOr types.bool;
        };
        "metrics" = mkOption {
          description = "Metrics enables metrics for this router.";
          type = types.nullOr types.bool;
        };
        "traceVerbosity" = mkOption {
          description = "TraceVerbosity defines the verbosity level of the tracing for this router.";
          type = types.nullOr types.str;
        };
        "tracing" = mkOption {
          description = "Tracing enables tracing for this router.";
          type = types.nullOr types.bool;
        };
      };

      config = {
        "accessLogs" = mkOverride 1002 null;
        "metrics" = mkOverride 1002 null;
        "traceVerbosity" = mkOverride 1002 null;
        "tracing" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.IngressRouteSpecRoutesServices" = {

      options = {
        "healthCheck" = mkOption {
          description = "Healthcheck defines health checks for ExternalName services.";
          type = types.nullOr (submoduleOf "traefik.io.v1alpha1.IngressRouteSpecRoutesServicesHealthCheck");
        };
        "kind" = mkOption {
          description = "Kind defines the kind of the Service.";
          type = types.nullOr types.str;
        };
        "name" = mkOption {
          description = "Name defines the name of the referenced Kubernetes Service or TraefikService.\nThe differentiation between the two is specified in the Kind field.";
          type = types.str;
        };
        "namespace" = mkOption {
          description = "Namespace defines the namespace of the referenced Kubernetes Service or TraefikService.";
          type = types.nullOr types.str;
        };
        "nativeLB" = mkOption {
          description = "NativeLB controls, when creating the load-balancer,\nwhether the LB's children are directly the pods IPs or if the only child is the Kubernetes Service clusterIP.\nThe Kubernetes Service itself does load-balance to the pods.\nBy default, NativeLB is false.";
          type = types.nullOr types.bool;
        };
        "nodePortLB" = mkOption {
          description = "NodePortLB controls, when creating the load-balancer,\nwhether the LB's children are directly the nodes internal IPs using the nodePort when the service type is NodePort.\nIt allows services to be reachable when Traefik runs externally from the Kubernetes cluster but within the same network of the nodes.\nBy default, NodePortLB is false.";
          type = types.nullOr types.bool;
        };
        "passHostHeader" = mkOption {
          description = "PassHostHeader defines whether the client Host header is forwarded to the upstream Kubernetes Service.\nBy default, passHostHeader is true.";
          type = types.nullOr types.bool;
        };
        "passiveHealthCheck" = mkOption {
          description = "PassiveHealthCheck defines passive health checks for ExternalName services.";
          type = types.nullOr (
            submoduleOf "traefik.io.v1alpha1.IngressRouteSpecRoutesServicesPassiveHealthCheck"
          );
        };
        "port" = mkOption {
          description = "Port defines the port of a Kubernetes Service.\nThis can be a reference to a named port.";
          type = types.nullOr (types.either types.int types.str);
        };
        "responseForwarding" = mkOption {
          description = "ResponseForwarding defines how Traefik forwards the response from the upstream Kubernetes Service to the client.";
          type = types.nullOr (
            submoduleOf "traefik.io.v1alpha1.IngressRouteSpecRoutesServicesResponseForwarding"
          );
        };
        "scheme" = mkOption {
          description = "Scheme defines the scheme to use for the request to the upstream Kubernetes Service.\nIt defaults to https when Kubernetes Service port is 443, http otherwise.";
          type = types.nullOr types.str;
        };
        "serversTransport" = mkOption {
          description = "ServersTransport defines the name of ServersTransport resource to use.\nIt allows to configure the transport between Traefik and your servers.\nCan only be used on a Kubernetes Service.";
          type = types.nullOr types.str;
        };
        "sticky" = mkOption {
          description = "Sticky defines the sticky sessions configuration.\nMore info: https://doc.traefik.io/traefik/v3.6/reference/routing-configuration/http/load-balancing/service/#sticky-sessions";
          type = types.nullOr (submoduleOf "traefik.io.v1alpha1.IngressRouteSpecRoutesServicesSticky");
        };
        "strategy" = mkOption {
          description = "Strategy defines the load balancing strategy between the servers.\nSupported values are: wrr (Weighed round-robin), p2c (Power of two choices), hrw (Highest Random Weight), and leasttime (Least-Time).\nRoundRobin value is deprecated and supported for backward compatibility.";
          type = types.nullOr types.str;
        };
        "weight" = mkOption {
          description = "Weight defines the weight and should only be specified when Name references a TraefikService object\n(and to be precise, one that embeds a Weighted Round Robin).";
          type = types.nullOr types.int;
        };
      };

      config = {
        "healthCheck" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
        "nativeLB" = mkOverride 1002 null;
        "nodePortLB" = mkOverride 1002 null;
        "passHostHeader" = mkOverride 1002 null;
        "passiveHealthCheck" = mkOverride 1002 null;
        "port" = mkOverride 1002 null;
        "responseForwarding" = mkOverride 1002 null;
        "scheme" = mkOverride 1002 null;
        "serversTransport" = mkOverride 1002 null;
        "sticky" = mkOverride 1002 null;
        "strategy" = mkOverride 1002 null;
        "weight" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.IngressRouteSpecRoutesServicesHealthCheck" = {

      options = {
        "followRedirects" = mkOption {
          description = "FollowRedirects defines whether redirects should be followed during the health check calls.\nDefault: true";
          type = types.nullOr types.bool;
        };
        "headers" = mkOption {
          description = "Headers defines custom headers to be sent to the health check endpoint.";
          type = types.nullOr (types.attrsOf types.str);
        };
        "hostname" = mkOption {
          description = "Hostname defines the value of hostname in the Host header of the health check request.";
          type = types.nullOr types.str;
        };
        "interval" = mkOption {
          description = "Interval defines the frequency of the health check calls for healthy targets.\nDefault: 30s";
          type = types.nullOr (types.either types.int types.str);
        };
        "method" = mkOption {
          description = "Method defines the healthcheck method.";
          type = types.nullOr types.str;
        };
        "mode" = mkOption {
          description = "Mode defines the health check mode.\nIf defined to grpc, will use the gRPC health check protocol to probe the server.\nDefault: http";
          type = types.nullOr types.str;
        };
        "path" = mkOption {
          description = "Path defines the server URL path for the health check endpoint.";
          type = types.nullOr types.str;
        };
        "port" = mkOption {
          description = "Port defines the server URL port for the health check endpoint.";
          type = types.nullOr types.int;
        };
        "scheme" = mkOption {
          description = "Scheme replaces the server URL scheme for the health check endpoint.";
          type = types.nullOr types.str;
        };
        "status" = mkOption {
          description = "Status defines the expected HTTP status code of the response to the health check request.";
          type = types.nullOr types.int;
        };
        "timeout" = mkOption {
          description = "Timeout defines the maximum duration Traefik will wait for a health check request before considering the server unhealthy.\nDefault: 5s";
          type = types.nullOr (types.either types.int types.str);
        };
        "unhealthyInterval" = mkOption {
          description = "UnhealthyInterval defines the frequency of the health check calls for unhealthy targets.\nWhen UnhealthyInterval is not defined, it defaults to the Interval value.\nDefault: 30s";
          type = types.nullOr (types.either types.int types.str);
        };
      };

      config = {
        "followRedirects" = mkOverride 1002 null;
        "headers" = mkOverride 1002 null;
        "hostname" = mkOverride 1002 null;
        "interval" = mkOverride 1002 null;
        "method" = mkOverride 1002 null;
        "mode" = mkOverride 1002 null;
        "path" = mkOverride 1002 null;
        "port" = mkOverride 1002 null;
        "scheme" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
        "timeout" = mkOverride 1002 null;
        "unhealthyInterval" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.IngressRouteSpecRoutesServicesPassiveHealthCheck" = {

      options = {
        "failureWindow" = mkOption {
          description = "FailureWindow defines the time window during which the failed attempts must occur for the server to be marked as unhealthy. It also defines for how long the server will be considered unhealthy.";
          type = types.nullOr (types.either types.int types.str);
        };
        "maxFailedAttempts" = mkOption {
          description = "MaxFailedAttempts is the number of consecutive failed attempts allowed within the failure window before marking the server as unhealthy.";
          type = types.nullOr types.int;
        };
      };

      config = {
        "failureWindow" = mkOverride 1002 null;
        "maxFailedAttempts" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.IngressRouteSpecRoutesServicesResponseForwarding" = {

      options = {
        "flushInterval" = mkOption {
          description = "FlushInterval defines the interval, in milliseconds, in between flushes to the client while copying the response body.\nA negative value means to flush immediately after each write to the client.\nThis configuration is ignored when ReverseProxy recognizes a response as a streaming response;\nfor such responses, writes are flushed to the client immediately.\nDefault: 100ms";
          type = types.nullOr types.str;
        };
      };

      config = {
        "flushInterval" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.IngressRouteSpecRoutesServicesSticky" = {

      options = {
        "cookie" = mkOption {
          description = "Cookie defines the sticky cookie configuration.";
          type = types.nullOr (submoduleOf "traefik.io.v1alpha1.IngressRouteSpecRoutesServicesStickyCookie");
        };
      };

      config = {
        "cookie" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.IngressRouteSpecRoutesServicesStickyCookie" = {

      options = {
        "domain" = mkOption {
          description = "Domain defines the host to which the cookie will be sent.\nMore info: https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Set-Cookie#domaindomain-value";
          type = types.nullOr types.str;
        };
        "httpOnly" = mkOption {
          description = "HTTPOnly defines whether the cookie can be accessed by client-side APIs, such as JavaScript.";
          type = types.nullOr types.bool;
        };
        "maxAge" = mkOption {
          description = "MaxAge defines the number of seconds until the cookie expires.\nWhen set to a negative number, the cookie expires immediately.\nWhen set to zero, the cookie never expires.";
          type = types.nullOr types.int;
        };
        "name" = mkOption {
          description = "Name defines the Cookie name.";
          type = types.nullOr types.str;
        };
        "path" = mkOption {
          description = "Path defines the path that must exist in the requested URL for the browser to send the Cookie header.\nWhen not provided the cookie will be sent on every request to the domain.\nMore info: https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Set-Cookie#pathpath-value";
          type = types.nullOr types.str;
        };
        "sameSite" = mkOption {
          description = "SameSite defines the same site policy.\nMore info: https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Set-Cookie/SameSite";
          type = types.nullOr types.str;
        };
        "secure" = mkOption {
          description = "Secure defines whether the cookie can only be transmitted over an encrypted connection (i.e. HTTPS).";
          type = types.nullOr types.bool;
        };
      };

      config = {
        "domain" = mkOverride 1002 null;
        "httpOnly" = mkOverride 1002 null;
        "maxAge" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "path" = mkOverride 1002 null;
        "sameSite" = mkOverride 1002 null;
        "secure" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.IngressRouteSpecTls" = {

      options = {
        "certResolver" = mkOption {
          description = "CertResolver defines the name of the certificate resolver to use.\nCert resolvers have to be configured in the static configuration.\nMore info: https://doc.traefik.io/traefik/v3.6/reference/install-configuration/tls/certificate-resolvers/acme/";
          type = types.nullOr types.str;
        };
        "domains" = mkOption {
          description = "Domains defines the list of domains that will be used to issue certificates.\nMore info: https://doc.traefik.io/traefik/v3.6/reference/routing-configuration/http/tls/tls-certificates/#domains";
          type = types.nullOr (types.listOf (submoduleOf "traefik.io.v1alpha1.IngressRouteSpecTlsDomains"));
        };
        "options" = mkOption {
          description = "Options defines the reference to a TLSOption, that specifies the parameters of the TLS connection.\nIf not defined, the `default` TLSOption is used.\nMore info: https://doc.traefik.io/traefik/v3.6/reference/routing-configuration/http/tls/tls-options/";
          type = types.nullOr (submoduleOf "traefik.io.v1alpha1.IngressRouteSpecTlsOptions");
        };
        "secretName" = mkOption {
          description = "SecretName is the name of the referenced Kubernetes Secret to specify the certificate details.";
          type = types.nullOr types.str;
        };
        "store" = mkOption {
          description = "Store defines the reference to the TLSStore, that will be used to store certificates.\nPlease note that only `default` TLSStore can be used.";
          type = types.nullOr (submoduleOf "traefik.io.v1alpha1.IngressRouteSpecTlsStore");
        };
      };

      config = {
        "certResolver" = mkOverride 1002 null;
        "domains" = mkOverride 1002 null;
        "options" = mkOverride 1002 null;
        "secretName" = mkOverride 1002 null;
        "store" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.IngressRouteSpecTlsDomains" = {

      options = {
        "main" = mkOption {
          description = "Main defines the main domain name.";
          type = types.nullOr types.str;
        };
        "sans" = mkOption {
          description = "SANs defines the subject alternative domain names.";
          type = types.nullOr (types.listOf types.str);
        };
      };

      config = {
        "main" = mkOverride 1002 null;
        "sans" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.IngressRouteSpecTlsOptions" = {

      options = {
        "name" = mkOption {
          description = "Name defines the name of the referenced TLSOption.\nMore info: https://doc.traefik.io/traefik/v3.6/reference/routing-configuration/kubernetes/crd/http/tlsoption/";
          type = types.str;
        };
        "namespace" = mkOption {
          description = "Namespace defines the namespace of the referenced TLSOption.\nMore info: https://doc.traefik.io/traefik/v3.6/reference/routing-configuration/kubernetes/crd/http/tlsoption/";
          type = types.nullOr types.str;
        };
      };

      config = {
        "namespace" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.IngressRouteSpecTlsStore" = {

      options = {
        "name" = mkOption {
          description = "Name defines the name of the referenced TLSStore.\nMore info: https://doc.traefik.io/traefik/v3.6/reference/routing-configuration/kubernetes/crd/http/tlsstore/";
          type = types.str;
        };
        "namespace" = mkOption {
          description = "Namespace defines the namespace of the referenced TLSStore.\nMore info: https://doc.traefik.io/traefik/v3.6/reference/routing-configuration/kubernetes/crd/http/tlsstore/";
          type = types.nullOr types.str;
        };
      };

      config = {
        "namespace" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.IngressRouteTCP" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object.\nServers should convert recognized schemas to the latest internal value, and\nmay reject unrecognized values.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = types.nullOr types.str;
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents.\nServers may infer this from the endpoint the client submits requests to.\nCannot be updated.\nIn CamelCase.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = types.nullOr types.str;
        };
        "metadata" = mkOption {
          description = "Standard object's metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = globalSubmoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta";
        };
        "spec" = mkOption {
          description = "IngressRouteTCPSpec defines the desired state of IngressRouteTCP.";
          type = submoduleOf "traefik.io.v1alpha1.IngressRouteTCPSpec";
        };
      };

      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.IngressRouteTCPSpec" = {

      options = {
        "entryPoints" = mkOption {
          description = "EntryPoints defines the list of entry point names to bind to.\nEntry points have to be configured in the static configuration.\nMore info: https://doc.traefik.io/traefik/v3.6/reference/install-configuration/entrypoints/\nDefault: all.";
          type = types.nullOr (types.listOf types.str);
        };
        "routes" = mkOption {
          description = "Routes defines the list of routes.";
          type = types.listOf (submoduleOf "traefik.io.v1alpha1.IngressRouteTCPSpecRoutes");
        };
        "tls" = mkOption {
          description = "TLS defines the TLS configuration on a layer 4 / TCP Route.\nMore info: https://doc.traefik.io/traefik/v3.6/reference/routing-configuration/tcp/routing/router/#tls";
          type = types.nullOr (submoduleOf "traefik.io.v1alpha1.IngressRouteTCPSpecTls");
        };
      };

      config = {
        "entryPoints" = mkOverride 1002 null;
        "tls" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.IngressRouteTCPSpecRoutes" = {

      options = {
        "match" = mkOption {
          description = "Match defines the router's rule.\nMore info: https://doc.traefik.io/traefik/v3.6/reference/routing-configuration/tcp/routing/rules-and-priority/";
          type = types.str;
        };
        "middlewares" = mkOption {
          description = "Middlewares defines the list of references to MiddlewareTCP resources.";
          type = types.nullOr (
            coerceAttrsOfSubmodulesToListByKey "traefik.io.v1alpha1.IngressRouteTCPSpecRoutesMiddlewares" "name"
              [ ]
          );
          apply = attrsToList;
        };
        "priority" = mkOption {
          description = "Priority defines the router's priority.\nMore info: https://doc.traefik.io/traefik/v3.6/reference/routing-configuration/tcp/routing/rules-and-priority/#priority";
          type = types.nullOr types.int;
        };
        "services" = mkOption {
          description = "Services defines the list of TCP services.";
          type = types.nullOr (
            coerceAttrsOfSubmodulesToListByKey "traefik.io.v1alpha1.IngressRouteTCPSpecRoutesServices" "name"
              [ ]
          );
          apply = attrsToList;
        };
        "syntax" = mkOption {
          description = "Syntax defines the router's rule syntax.\nMore info: https://doc.traefik.io/traefik/v3.6/reference/routing-configuration/tcp/routing/rules-and-priority/#rulesyntax\n\nDeprecated: Please do not use this field and rewrite the router rules to use the v3 syntax.";
          type = types.nullOr types.str;
        };
      };

      config = {
        "middlewares" = mkOverride 1002 null;
        "priority" = mkOverride 1002 null;
        "services" = mkOverride 1002 null;
        "syntax" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.IngressRouteTCPSpecRoutesMiddlewares" = {

      options = {
        "name" = mkOption {
          description = "Name defines the name of the referenced Traefik resource.";
          type = types.str;
        };
        "namespace" = mkOption {
          description = "Namespace defines the namespace of the referenced Traefik resource.";
          type = types.nullOr types.str;
        };
      };

      config = {
        "namespace" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.IngressRouteTCPSpecRoutesServices" = {

      options = {
        "name" = mkOption {
          description = "Name defines the name of the referenced Kubernetes Service.";
          type = types.str;
        };
        "namespace" = mkOption {
          description = "Namespace defines the namespace of the referenced Kubernetes Service.";
          type = types.nullOr types.str;
        };
        "nativeLB" = mkOption {
          description = "NativeLB controls, when creating the load-balancer,\nwhether the LB's children are directly the pods IPs or if the only child is the Kubernetes Service clusterIP.\nThe Kubernetes Service itself does load-balance to the pods.\nBy default, NativeLB is false.";
          type = types.nullOr types.bool;
        };
        "nodePortLB" = mkOption {
          description = "NodePortLB controls, when creating the load-balancer,\nwhether the LB's children are directly the nodes internal IPs using the nodePort when the service type is NodePort.\nIt allows services to be reachable when Traefik runs externally from the Kubernetes cluster but within the same network of the nodes.\nBy default, NodePortLB is false.";
          type = types.nullOr types.bool;
        };
        "port" = mkOption {
          description = "Port defines the port of a Kubernetes Service.\nThis can be a reference to a named port.";
          type = types.either types.int types.str;
        };
        "proxyProtocol" = mkOption {
          description = "ProxyProtocol defines the PROXY protocol configuration.\nMore info: https://doc.traefik.io/traefik/v3.6/reference/routing-configuration/tcp/service/#proxy-protocol\n\nDeprecated: ProxyProtocol will not be supported in future APIVersions, please use ServersTransport to configure ProxyProtocol instead.";
          type = types.nullOr (
            submoduleOf "traefik.io.v1alpha1.IngressRouteTCPSpecRoutesServicesProxyProtocol"
          );
        };
        "serversTransport" = mkOption {
          description = "ServersTransport defines the name of ServersTransportTCP resource to use.\nIt allows to configure the transport between Traefik and your servers.\nCan only be used on a Kubernetes Service.";
          type = types.nullOr types.str;
        };
        "terminationDelay" = mkOption {
          description = "TerminationDelay defines the deadline that the proxy sets, after one of its connected peers indicates\nit has closed the writing capability of its connection, to close the reading capability as well,\nhence fully terminating the connection.\nIt is a duration in milliseconds, defaulting to 100.\nA negative value means an infinite deadline (i.e. the reading capability is never closed).\n\nDeprecated: TerminationDelay will not be supported in future APIVersions, please use ServersTransport to configure the TerminationDelay instead.";
          type = types.nullOr types.int;
        };
        "tls" = mkOption {
          description = "TLS determines whether to use TLS when dialing with the backend.";
          type = types.nullOr types.bool;
        };
        "weight" = mkOption {
          description = "Weight defines the weight used when balancing requests between multiple Kubernetes Service.";
          type = types.nullOr types.int;
        };
      };

      config = {
        "namespace" = mkOverride 1002 null;
        "nativeLB" = mkOverride 1002 null;
        "nodePortLB" = mkOverride 1002 null;
        "proxyProtocol" = mkOverride 1002 null;
        "serversTransport" = mkOverride 1002 null;
        "terminationDelay" = mkOverride 1002 null;
        "tls" = mkOverride 1002 null;
        "weight" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.IngressRouteTCPSpecRoutesServicesProxyProtocol" = {

      options = {
        "version" = mkOption {
          description = "Version defines the PROXY Protocol version to use.";
          type = types.nullOr types.int;
        };
      };

      config = {
        "version" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.IngressRouteTCPSpecTls" = {

      options = {
        "certResolver" = mkOption {
          description = "CertResolver defines the name of the certificate resolver to use.\nCert resolvers have to be configured in the static configuration.\nMore info: https://doc.traefik.io/traefik/v3.6/reference/install-configuration/tls/certificate-resolvers/acme/";
          type = types.nullOr types.str;
        };
        "domains" = mkOption {
          description = "Domains defines the list of domains that will be used to issue certificates.\nMore info: https://doc.traefik.io/traefik/v3.6/reference/routing-configuration/tcp/tls/#domains";
          type = types.nullOr (
            types.listOf (submoduleOf "traefik.io.v1alpha1.IngressRouteTCPSpecTlsDomains")
          );
        };
        "options" = mkOption {
          description = "Options defines the reference to a TLSOption, that specifies the parameters of the TLS connection.\nIf not defined, the `default` TLSOption is used.\nMore info: https://doc.traefik.io/traefik/v3.6/reference/routing-configuration/tcp/tls/#tls-options";
          type = types.nullOr (submoduleOf "traefik.io.v1alpha1.IngressRouteTCPSpecTlsOptions");
        };
        "passthrough" = mkOption {
          description = "Passthrough defines whether a TLS router will terminate the TLS connection.";
          type = types.nullOr types.bool;
        };
        "secretName" = mkOption {
          description = "SecretName is the name of the referenced Kubernetes Secret to specify the certificate details.";
          type = types.nullOr types.str;
        };
        "store" = mkOption {
          description = "Store defines the reference to the TLSStore, that will be used to store certificates.\nPlease note that only `default` TLSStore can be used.";
          type = types.nullOr (submoduleOf "traefik.io.v1alpha1.IngressRouteTCPSpecTlsStore");
        };
      };

      config = {
        "certResolver" = mkOverride 1002 null;
        "domains" = mkOverride 1002 null;
        "options" = mkOverride 1002 null;
        "passthrough" = mkOverride 1002 null;
        "secretName" = mkOverride 1002 null;
        "store" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.IngressRouteTCPSpecTlsDomains" = {

      options = {
        "main" = mkOption {
          description = "Main defines the main domain name.";
          type = types.nullOr types.str;
        };
        "sans" = mkOption {
          description = "SANs defines the subject alternative domain names.";
          type = types.nullOr (types.listOf types.str);
        };
      };

      config = {
        "main" = mkOverride 1002 null;
        "sans" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.IngressRouteTCPSpecTlsOptions" = {

      options = {
        "name" = mkOption {
          description = "Name defines the name of the referenced Traefik resource.";
          type = types.str;
        };
        "namespace" = mkOption {
          description = "Namespace defines the namespace of the referenced Traefik resource.";
          type = types.nullOr types.str;
        };
      };

      config = {
        "namespace" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.IngressRouteTCPSpecTlsStore" = {

      options = {
        "name" = mkOption {
          description = "Name defines the name of the referenced Traefik resource.";
          type = types.str;
        };
        "namespace" = mkOption {
          description = "Namespace defines the namespace of the referenced Traefik resource.";
          type = types.nullOr types.str;
        };
      };

      config = {
        "namespace" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.IngressRouteUDP" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object.\nServers should convert recognized schemas to the latest internal value, and\nmay reject unrecognized values.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = types.nullOr types.str;
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents.\nServers may infer this from the endpoint the client submits requests to.\nCannot be updated.\nIn CamelCase.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = types.nullOr types.str;
        };
        "metadata" = mkOption {
          description = "Standard object's metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = globalSubmoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta";
        };
        "spec" = mkOption {
          description = "IngressRouteUDPSpec defines the desired state of a IngressRouteUDP.";
          type = submoduleOf "traefik.io.v1alpha1.IngressRouteUDPSpec";
        };
      };

      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.IngressRouteUDPSpec" = {

      options = {
        "entryPoints" = mkOption {
          description = "EntryPoints defines the list of entry point names to bind to.\nEntry points have to be configured in the static configuration.\nMore info: https://doc.traefik.io/traefik/v3.6/reference/install-configuration/entrypoints/\nDefault: all.";
          type = types.nullOr (types.listOf types.str);
        };
        "routes" = mkOption {
          description = "Routes defines the list of routes.";
          type = types.listOf (submoduleOf "traefik.io.v1alpha1.IngressRouteUDPSpecRoutes");
        };
      };

      config = {
        "entryPoints" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.IngressRouteUDPSpecRoutes" = {

      options = {
        "services" = mkOption {
          description = "Services defines the list of UDP services.";
          type = types.nullOr (
            coerceAttrsOfSubmodulesToListByKey "traefik.io.v1alpha1.IngressRouteUDPSpecRoutesServices" "name"
              [ ]
          );
          apply = attrsToList;
        };
      };

      config = {
        "services" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.IngressRouteUDPSpecRoutesServices" = {

      options = {
        "name" = mkOption {
          description = "Name defines the name of the referenced Kubernetes Service.";
          type = types.str;
        };
        "namespace" = mkOption {
          description = "Namespace defines the namespace of the referenced Kubernetes Service.";
          type = types.nullOr types.str;
        };
        "nativeLB" = mkOption {
          description = "NativeLB controls, when creating the load-balancer,\nwhether the LB's children are directly the pods IPs or if the only child is the Kubernetes Service clusterIP.\nThe Kubernetes Service itself does load-balance to the pods.\nBy default, NativeLB is false.";
          type = types.nullOr types.bool;
        };
        "nodePortLB" = mkOption {
          description = "NodePortLB controls, when creating the load-balancer,\nwhether the LB's children are directly the nodes internal IPs using the nodePort when the service type is NodePort.\nIt allows services to be reachable when Traefik runs externally from the Kubernetes cluster but within the same network of the nodes.\nBy default, NodePortLB is false.";
          type = types.nullOr types.bool;
        };
        "port" = mkOption {
          description = "Port defines the port of a Kubernetes Service.\nThis can be a reference to a named port.";
          type = types.either types.int types.str;
        };
        "weight" = mkOption {
          description = "Weight defines the weight used when balancing requests between multiple Kubernetes Service.";
          type = types.nullOr types.int;
        };
      };

      config = {
        "namespace" = mkOverride 1002 null;
        "nativeLB" = mkOverride 1002 null;
        "nodePortLB" = mkOverride 1002 null;
        "weight" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.Middleware" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object.\nServers should convert recognized schemas to the latest internal value, and\nmay reject unrecognized values.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = types.nullOr types.str;
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents.\nServers may infer this from the endpoint the client submits requests to.\nCannot be updated.\nIn CamelCase.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = types.nullOr types.str;
        };
        "metadata" = mkOption {
          description = "Standard object's metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = globalSubmoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta";
        };
        "spec" = mkOption {
          description = "MiddlewareSpec defines the desired state of a Middleware.";
          type = submoduleOf "traefik.io.v1alpha1.MiddlewareSpec";
        };
      };

      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.MiddlewareSpec" = {

      options = {
        "addPrefix" = mkOption {
          description = "AddPrefix holds the add prefix middleware configuration.\nThis middleware updates the path of a request before forwarding it.\nMore info: https://doc.traefik.io/traefik/v3.6/middlewares/http/addprefix/";
          type = types.nullOr (submoduleOf "traefik.io.v1alpha1.MiddlewareSpecAddPrefix");
        };
        "basicAuth" = mkOption {
          description = "BasicAuth holds the basic auth middleware configuration.\nThis middleware restricts access to your services to known users.\nMore info: https://doc.traefik.io/traefik/v3.6/reference/routing-configuration/http/middlewares/basicauth/";
          type = types.nullOr (submoduleOf "traefik.io.v1alpha1.MiddlewareSpecBasicAuth");
        };
        "buffering" = mkOption {
          description = "Buffering holds the buffering middleware configuration.\nThis middleware retries or limits the size of requests that can be forwarded to backends.\nMore info: https://doc.traefik.io/traefik/v3.6/middlewares/http/buffering/#maxrequestbodybytes";
          type = types.nullOr (submoduleOf "traefik.io.v1alpha1.MiddlewareSpecBuffering");
        };
        "chain" = mkOption {
          description = "Chain holds the configuration of the chain middleware.\nThis middleware enables to define reusable combinations of other pieces of middleware.\nMore info: https://doc.traefik.io/traefik/v3.6/reference/routing-configuration/http/middlewares/chain/";
          type = types.nullOr (submoduleOf "traefik.io.v1alpha1.MiddlewareSpecChain");
        };
        "circuitBreaker" = mkOption {
          description = "CircuitBreaker holds the circuit breaker configuration.";
          type = types.nullOr (submoduleOf "traefik.io.v1alpha1.MiddlewareSpecCircuitBreaker");
        };
        "compress" = mkOption {
          description = "Compress holds the compress middleware configuration.\nThis middleware compresses responses before sending them to the client, using gzip, brotli, or zstd compression.\nMore info: https://doc.traefik.io/traefik/v3.6/reference/routing-configuration/http/middlewares/compress/";
          type = types.nullOr (submoduleOf "traefik.io.v1alpha1.MiddlewareSpecCompress");
        };
        "contentType" = mkOption {
          description = "ContentType holds the content-type middleware configuration.\nThis middleware exists to enable the correct behavior until at least the default one can be changed in a future version.";
          type = types.nullOr (submoduleOf "traefik.io.v1alpha1.MiddlewareSpecContentType");
        };
        "digestAuth" = mkOption {
          description = "DigestAuth holds the digest auth middleware configuration.\nThis middleware restricts access to your services to known users.\nMore info: https://doc.traefik.io/traefik/v3.6/reference/routing-configuration/http/middlewares/digestauth/";
          type = types.nullOr (submoduleOf "traefik.io.v1alpha1.MiddlewareSpecDigestAuth");
        };
        "errors" = mkOption {
          description = "ErrorPage holds the custom error middleware configuration.\nThis middleware returns a custom page in lieu of the default, according to configured ranges of HTTP Status codes.\nMore info: https://doc.traefik.io/traefik/v3.6/reference/routing-configuration/http/middlewares/errorpages/";
          type = types.nullOr (submoduleOf "traefik.io.v1alpha1.MiddlewareSpecErrors");
        };
        "forwardAuth" = mkOption {
          description = "ForwardAuth holds the forward auth middleware configuration.\nThis middleware delegates the request authentication to a Service.\nMore info: https://doc.traefik.io/traefik/v3.6/reference/routing-configuration/http/middlewares/forwardauth/";
          type = types.nullOr (submoduleOf "traefik.io.v1alpha1.MiddlewareSpecForwardAuth");
        };
        "grpcWeb" = mkOption {
          description = "GrpcWeb holds the gRPC web middleware configuration.\nThis middleware converts a gRPC web request to an HTTP/2 gRPC request.";
          type = types.nullOr (submoduleOf "traefik.io.v1alpha1.MiddlewareSpecGrpcWeb");
        };
        "headers" = mkOption {
          description = "Headers holds the headers middleware configuration.\nThis middleware manages the requests and responses headers.\nMore info: https://doc.traefik.io/traefik/v3.6/middlewares/http/headers/#customrequestheaders";
          type = types.nullOr (submoduleOf "traefik.io.v1alpha1.MiddlewareSpecHeaders");
        };
        "inFlightReq" = mkOption {
          description = "InFlightReq holds the in-flight request middleware configuration.\nThis middleware limits the number of requests being processed and served concurrently.\nMore info: https://doc.traefik.io/traefik/v3.6/middlewares/http/inflightreq/";
          type = types.nullOr (submoduleOf "traefik.io.v1alpha1.MiddlewareSpecInFlightReq");
        };
        "ipAllowList" = mkOption {
          description = "IPAllowList holds the IP allowlist middleware configuration.\nThis middleware limits allowed requests based on the client IP.\nMore info: https://doc.traefik.io/traefik/v3.6/middlewares/http/ipallowlist/";
          type = types.nullOr (submoduleOf "traefik.io.v1alpha1.MiddlewareSpecIpAllowList");
        };
        "ipWhiteList" = mkOption {
          description = "Deprecated: please use IPAllowList instead.";
          type = types.nullOr (submoduleOf "traefik.io.v1alpha1.MiddlewareSpecIpWhiteList");
        };
        "passTLSClientCert" = mkOption {
          description = "PassTLSClientCert holds the pass TLS client cert middleware configuration.\nThis middleware adds the selected data from the passed client TLS certificate to a header.\nMore info: https://doc.traefik.io/traefik/v3.6/middlewares/http/passtlsclientcert/";
          type = types.nullOr (submoduleOf "traefik.io.v1alpha1.MiddlewareSpecPassTLSClientCert");
        };
        "plugin" = mkOption {
          description = "Plugin defines the middleware plugin configuration.\nMore info: https://doc.traefik.io/traefik/v3.6/reference/routing-configuration/http/middlewares/overview/#community-middlewares";
          type = types.nullOr types.attrs;
        };
        "rateLimit" = mkOption {
          description = "RateLimit holds the rate limit configuration.\nThis middleware ensures that services will receive a fair amount of requests, and allows one to define what fair is.\nMore info: https://doc.traefik.io/traefik/v3.6/reference/routing-configuration/http/middlewares/ratelimit/";
          type = types.nullOr (submoduleOf "traefik.io.v1alpha1.MiddlewareSpecRateLimit");
        };
        "redirectRegex" = mkOption {
          description = "RedirectRegex holds the redirect regex middleware configuration.\nThis middleware redirects a request using regex matching and replacement.\nMore info: https://doc.traefik.io/traefik/v3.6/middlewares/http/redirectregex/#regex";
          type = types.nullOr (submoduleOf "traefik.io.v1alpha1.MiddlewareSpecRedirectRegex");
        };
        "redirectScheme" = mkOption {
          description = "RedirectScheme holds the redirect scheme middleware configuration.\nThis middleware redirects requests from a scheme/port to another.\nMore info: https://doc.traefik.io/traefik/v3.6/middlewares/http/redirectscheme/";
          type = types.nullOr (submoduleOf "traefik.io.v1alpha1.MiddlewareSpecRedirectScheme");
        };
        "replacePath" = mkOption {
          description = "ReplacePath holds the replace path middleware configuration.\nThis middleware replaces the path of the request URL and store the original path in an X-Replaced-Path header.\nMore info: https://doc.traefik.io/traefik/v3.6/middlewares/http/replacepath/";
          type = types.nullOr (submoduleOf "traefik.io.v1alpha1.MiddlewareSpecReplacePath");
        };
        "replacePathRegex" = mkOption {
          description = "ReplacePathRegex holds the replace path regex middleware configuration.\nThis middleware replaces the path of a URL using regex matching and replacement.\nMore info: https://doc.traefik.io/traefik/v3.6/middlewares/http/replacepathregex/";
          type = types.nullOr (submoduleOf "traefik.io.v1alpha1.MiddlewareSpecReplacePathRegex");
        };
        "retry" = mkOption {
          description = "Retry holds the retry middleware configuration.\nThis middleware reissues requests a given number of times to a backend server if that server does not reply.\nAs soon as the server answers, the middleware stops retrying, regardless of the response status.\nMore info: https://doc.traefik.io/traefik/v3.6/reference/routing-configuration/http/middlewares/retry/";
          type = types.nullOr (submoduleOf "traefik.io.v1alpha1.MiddlewareSpecRetry");
        };
        "stripPrefix" = mkOption {
          description = "StripPrefix holds the strip prefix middleware configuration.\nThis middleware removes the specified prefixes from the URL path.\nMore info: https://doc.traefik.io/traefik/v3.6/middlewares/http/stripprefix/";
          type = types.nullOr (submoduleOf "traefik.io.v1alpha1.MiddlewareSpecStripPrefix");
        };
        "stripPrefixRegex" = mkOption {
          description = "StripPrefixRegex holds the strip prefix regex middleware configuration.\nThis middleware removes the matching prefixes from the URL path.\nMore info: https://doc.traefik.io/traefik/v3.6/middlewares/http/stripprefixregex/";
          type = types.nullOr (submoduleOf "traefik.io.v1alpha1.MiddlewareSpecStripPrefixRegex");
        };
      };

      config = {
        "addPrefix" = mkOverride 1002 null;
        "basicAuth" = mkOverride 1002 null;
        "buffering" = mkOverride 1002 null;
        "chain" = mkOverride 1002 null;
        "circuitBreaker" = mkOverride 1002 null;
        "compress" = mkOverride 1002 null;
        "contentType" = mkOverride 1002 null;
        "digestAuth" = mkOverride 1002 null;
        "errors" = mkOverride 1002 null;
        "forwardAuth" = mkOverride 1002 null;
        "grpcWeb" = mkOverride 1002 null;
        "headers" = mkOverride 1002 null;
        "inFlightReq" = mkOverride 1002 null;
        "ipAllowList" = mkOverride 1002 null;
        "ipWhiteList" = mkOverride 1002 null;
        "passTLSClientCert" = mkOverride 1002 null;
        "plugin" = mkOverride 1002 null;
        "rateLimit" = mkOverride 1002 null;
        "redirectRegex" = mkOverride 1002 null;
        "redirectScheme" = mkOverride 1002 null;
        "replacePath" = mkOverride 1002 null;
        "replacePathRegex" = mkOverride 1002 null;
        "retry" = mkOverride 1002 null;
        "stripPrefix" = mkOverride 1002 null;
        "stripPrefixRegex" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.MiddlewareSpecAddPrefix" = {

      options = {
        "prefix" = mkOption {
          description = "Prefix is the string to add before the current path in the requested URL.\nIt should include a leading slash (/).";
          type = types.nullOr types.str;
        };
      };

      config = {
        "prefix" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.MiddlewareSpecBasicAuth" = {

      options = {
        "headerField" = mkOption {
          description = "HeaderField defines a header field to store the authenticated user.\nMore info: https://doc.traefik.io/traefik/v3.6/reference/routing-configuration/http/middlewares/basicauth/#headerfield";
          type = types.nullOr types.str;
        };
        "realm" = mkOption {
          description = "Realm allows the protected resources on a server to be partitioned into a set of protection spaces, each with its own authentication scheme.\nDefault: traefik.";
          type = types.nullOr types.str;
        };
        "removeHeader" = mkOption {
          description = "RemoveHeader sets the removeHeader option to true to remove the authorization header before forwarding the request to your service.\nDefault: false.";
          type = types.nullOr types.bool;
        };
        "secret" = mkOption {
          description = "Secret is the name of the referenced Kubernetes Secret containing user credentials.";
          type = types.nullOr types.str;
        };
      };

      config = {
        "headerField" = mkOverride 1002 null;
        "realm" = mkOverride 1002 null;
        "removeHeader" = mkOverride 1002 null;
        "secret" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.MiddlewareSpecBuffering" = {

      options = {
        "maxRequestBodyBytes" = mkOption {
          description = "MaxRequestBodyBytes defines the maximum allowed body size for the request (in bytes).\nIf the request exceeds the allowed size, it is not forwarded to the service, and the client gets a 413 (Request Entity Too Large) response.\nDefault: 0 (no maximum).";
          type = types.nullOr types.int;
        };
        "maxResponseBodyBytes" = mkOption {
          description = "MaxResponseBodyBytes defines the maximum allowed response size from the service (in bytes).\nIf the response exceeds the allowed size, it is not forwarded to the client. The client gets a 500 (Internal Server Error) response instead.\nDefault: 0 (no maximum).";
          type = types.nullOr types.int;
        };
        "memRequestBodyBytes" = mkOption {
          description = "MemRequestBodyBytes defines the threshold (in bytes) from which the request will be buffered on disk instead of in memory.\nDefault: 1048576 (1Mi).";
          type = types.nullOr types.int;
        };
        "memResponseBodyBytes" = mkOption {
          description = "MemResponseBodyBytes defines the threshold (in bytes) from which the response will be buffered on disk instead of in memory.\nDefault: 1048576 (1Mi).";
          type = types.nullOr types.int;
        };
        "retryExpression" = mkOption {
          description = "RetryExpression defines the retry conditions.\nIt is a logical combination of functions with operators AND (&&) and OR (||).\nMore info: https://doc.traefik.io/traefik/v3.6/middlewares/http/buffering/#retryexpression";
          type = types.nullOr types.str;
        };
      };

      config = {
        "maxRequestBodyBytes" = mkOverride 1002 null;
        "maxResponseBodyBytes" = mkOverride 1002 null;
        "memRequestBodyBytes" = mkOverride 1002 null;
        "memResponseBodyBytes" = mkOverride 1002 null;
        "retryExpression" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.MiddlewareSpecChain" = {

      options = {
        "middlewares" = mkOption {
          description = "Middlewares is the list of MiddlewareRef which composes the chain.";
          type = types.nullOr (
            coerceAttrsOfSubmodulesToListByKey "traefik.io.v1alpha1.MiddlewareSpecChainMiddlewares" "name" [ ]
          );
          apply = attrsToList;
        };
      };

      config = {
        "middlewares" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.MiddlewareSpecChainMiddlewares" = {

      options = {
        "name" = mkOption {
          description = "Name defines the name of the referenced Middleware resource.";
          type = types.str;
        };
        "namespace" = mkOption {
          description = "Namespace defines the namespace of the referenced Middleware resource.";
          type = types.nullOr types.str;
        };
      };

      config = {
        "namespace" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.MiddlewareSpecCircuitBreaker" = {

      options = {
        "checkPeriod" = mkOption {
          description = "CheckPeriod is the interval between successive checks of the circuit breaker condition (when in standby state).";
          type = types.nullOr (types.either types.int types.str);
        };
        "expression" = mkOption {
          description = "Expression is the condition that triggers the tripped state.";
          type = types.nullOr types.str;
        };
        "fallbackDuration" = mkOption {
          description = "FallbackDuration is the duration for which the circuit breaker will wait before trying to recover (from a tripped state).";
          type = types.nullOr (types.either types.int types.str);
        };
        "recoveryDuration" = mkOption {
          description = "RecoveryDuration is the duration for which the circuit breaker will try to recover (as soon as it is in recovering state).";
          type = types.nullOr (types.either types.int types.str);
        };
        "responseCode" = mkOption {
          description = "ResponseCode is the status code that the circuit breaker will return while it is in the open state.";
          type = types.nullOr types.int;
        };
      };

      config = {
        "checkPeriod" = mkOverride 1002 null;
        "expression" = mkOverride 1002 null;
        "fallbackDuration" = mkOverride 1002 null;
        "recoveryDuration" = mkOverride 1002 null;
        "responseCode" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.MiddlewareSpecCompress" = {

      options = {
        "defaultEncoding" = mkOption {
          description = "DefaultEncoding specifies the default encoding if the `Accept-Encoding` header is not in the request or contains a wildcard (`*`).";
          type = types.nullOr types.str;
        };
        "encodings" = mkOption {
          description = "Encodings defines the list of supported compression algorithms.";
          type = types.nullOr (types.listOf types.str);
        };
        "excludedContentTypes" = mkOption {
          description = "ExcludedContentTypes defines the list of content types to compare the Content-Type header of the incoming requests and responses before compressing.\n`application/grpc` is always excluded.";
          type = types.nullOr (types.listOf types.str);
        };
        "includedContentTypes" = mkOption {
          description = "IncludedContentTypes defines the list of content types to compare the Content-Type header of the responses before compressing.";
          type = types.nullOr (types.listOf types.str);
        };
        "minResponseBodyBytes" = mkOption {
          description = "MinResponseBodyBytes defines the minimum amount of bytes a response body must have to be compressed.\nDefault: 1024.";
          type = types.nullOr types.int;
        };
      };

      config = {
        "defaultEncoding" = mkOverride 1002 null;
        "encodings" = mkOverride 1002 null;
        "excludedContentTypes" = mkOverride 1002 null;
        "includedContentTypes" = mkOverride 1002 null;
        "minResponseBodyBytes" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.MiddlewareSpecContentType" = {

      options = {
        "autoDetect" = mkOption {
          description = "AutoDetect specifies whether to let the `Content-Type` header, if it has not been set by the backend,\nbe automatically set to a value derived from the contents of the response.\n\nDeprecated: AutoDetect option is deprecated, Content-Type middleware is only meant to be used to enable the content-type detection, please remove any usage of this option.";
          type = types.nullOr types.bool;
        };
      };

      config = {
        "autoDetect" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.MiddlewareSpecDigestAuth" = {

      options = {
        "headerField" = mkOption {
          description = "HeaderField defines a header field to store the authenticated user.\nMore info: https://doc.traefik.io/traefik/v3.6/reference/routing-configuration/http/middlewares/digestauth/#headerfield";
          type = types.nullOr types.str;
        };
        "realm" = mkOption {
          description = "Realm allows the protected resources on a server to be partitioned into a set of protection spaces, each with its own authentication scheme.\nDefault: traefik.";
          type = types.nullOr types.str;
        };
        "removeHeader" = mkOption {
          description = "RemoveHeader defines whether to remove the authorization header before forwarding the request to the backend.";
          type = types.nullOr types.bool;
        };
        "secret" = mkOption {
          description = "Secret is the name of the referenced Kubernetes Secret containing user credentials.";
          type = types.nullOr types.str;
        };
      };

      config = {
        "headerField" = mkOverride 1002 null;
        "realm" = mkOverride 1002 null;
        "removeHeader" = mkOverride 1002 null;
        "secret" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.MiddlewareSpecErrors" = {

      options = {
        "query" = mkOption {
          description = "Query defines the URL for the error page (hosted by service).\nThe {status} variable can be used in order to insert the status code in the URL.\nThe {originalStatus} variable can be used in order to insert the upstream status code in the URL.\nThe {url} variable can be used in order to insert the escaped request URL.";
          type = types.nullOr types.str;
        };
        "service" = mkOption {
          description = "Service defines the reference to a Kubernetes Service that will serve the error page.\nMore info: https://doc.traefik.io/traefik/v3.6/reference/routing-configuration/http/middlewares/errorpages/#service";
          type = types.nullOr (submoduleOf "traefik.io.v1alpha1.MiddlewareSpecErrorsService");
        };
        "status" = mkOption {
          description = "Status defines which status or range of statuses should result in an error page.\nIt can be either a status code as a number (500),\nas multiple comma-separated numbers (500,502),\nas ranges by separating two codes with a dash (500-599),\nor a combination of the two (404,418,500-599).";
          type = types.nullOr (types.listOf types.str);
        };
        "statusRewrites" = mkOption {
          description = "StatusRewrites defines a mapping of status codes that should be returned instead of the original error status codes.\nFor example: \"418\": 404 or \"410-418\": 404";
          type = types.nullOr (types.attrsOf types.int);
        };
      };

      config = {
        "query" = mkOverride 1002 null;
        "service" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
        "statusRewrites" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.MiddlewareSpecErrorsService" = {

      options = {
        "healthCheck" = mkOption {
          description = "Healthcheck defines health checks for ExternalName services.";
          type = types.nullOr (submoduleOf "traefik.io.v1alpha1.MiddlewareSpecErrorsServiceHealthCheck");
        };
        "kind" = mkOption {
          description = "Kind defines the kind of the Service.";
          type = types.nullOr types.str;
        };
        "name" = mkOption {
          description = "Name defines the name of the referenced Kubernetes Service or TraefikService.\nThe differentiation between the two is specified in the Kind field.";
          type = types.str;
        };
        "namespace" = mkOption {
          description = "Namespace defines the namespace of the referenced Kubernetes Service or TraefikService.";
          type = types.nullOr types.str;
        };
        "nativeLB" = mkOption {
          description = "NativeLB controls, when creating the load-balancer,\nwhether the LB's children are directly the pods IPs or if the only child is the Kubernetes Service clusterIP.\nThe Kubernetes Service itself does load-balance to the pods.\nBy default, NativeLB is false.";
          type = types.nullOr types.bool;
        };
        "nodePortLB" = mkOption {
          description = "NodePortLB controls, when creating the load-balancer,\nwhether the LB's children are directly the nodes internal IPs using the nodePort when the service type is NodePort.\nIt allows services to be reachable when Traefik runs externally from the Kubernetes cluster but within the same network of the nodes.\nBy default, NodePortLB is false.";
          type = types.nullOr types.bool;
        };
        "passHostHeader" = mkOption {
          description = "PassHostHeader defines whether the client Host header is forwarded to the upstream Kubernetes Service.\nBy default, passHostHeader is true.";
          type = types.nullOr types.bool;
        };
        "passiveHealthCheck" = mkOption {
          description = "PassiveHealthCheck defines passive health checks for ExternalName services.";
          type = types.nullOr (
            submoduleOf "traefik.io.v1alpha1.MiddlewareSpecErrorsServicePassiveHealthCheck"
          );
        };
        "port" = mkOption {
          description = "Port defines the port of a Kubernetes Service.\nThis can be a reference to a named port.";
          type = types.nullOr (types.either types.int types.str);
        };
        "responseForwarding" = mkOption {
          description = "ResponseForwarding defines how Traefik forwards the response from the upstream Kubernetes Service to the client.";
          type = types.nullOr (
            submoduleOf "traefik.io.v1alpha1.MiddlewareSpecErrorsServiceResponseForwarding"
          );
        };
        "scheme" = mkOption {
          description = "Scheme defines the scheme to use for the request to the upstream Kubernetes Service.\nIt defaults to https when Kubernetes Service port is 443, http otherwise.";
          type = types.nullOr types.str;
        };
        "serversTransport" = mkOption {
          description = "ServersTransport defines the name of ServersTransport resource to use.\nIt allows to configure the transport between Traefik and your servers.\nCan only be used on a Kubernetes Service.";
          type = types.nullOr types.str;
        };
        "sticky" = mkOption {
          description = "Sticky defines the sticky sessions configuration.\nMore info: https://doc.traefik.io/traefik/v3.6/reference/routing-configuration/http/load-balancing/service/#sticky-sessions";
          type = types.nullOr (submoduleOf "traefik.io.v1alpha1.MiddlewareSpecErrorsServiceSticky");
        };
        "strategy" = mkOption {
          description = "Strategy defines the load balancing strategy between the servers.\nSupported values are: wrr (Weighed round-robin), p2c (Power of two choices), hrw (Highest Random Weight), and leasttime (Least-Time).\nRoundRobin value is deprecated and supported for backward compatibility.";
          type = types.nullOr types.str;
        };
        "weight" = mkOption {
          description = "Weight defines the weight and should only be specified when Name references a TraefikService object\n(and to be precise, one that embeds a Weighted Round Robin).";
          type = types.nullOr types.int;
        };
      };

      config = {
        "healthCheck" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
        "nativeLB" = mkOverride 1002 null;
        "nodePortLB" = mkOverride 1002 null;
        "passHostHeader" = mkOverride 1002 null;
        "passiveHealthCheck" = mkOverride 1002 null;
        "port" = mkOverride 1002 null;
        "responseForwarding" = mkOverride 1002 null;
        "scheme" = mkOverride 1002 null;
        "serversTransport" = mkOverride 1002 null;
        "sticky" = mkOverride 1002 null;
        "strategy" = mkOverride 1002 null;
        "weight" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.MiddlewareSpecErrorsServiceHealthCheck" = {

      options = {
        "followRedirects" = mkOption {
          description = "FollowRedirects defines whether redirects should be followed during the health check calls.\nDefault: true";
          type = types.nullOr types.bool;
        };
        "headers" = mkOption {
          description = "Headers defines custom headers to be sent to the health check endpoint.";
          type = types.nullOr (types.attrsOf types.str);
        };
        "hostname" = mkOption {
          description = "Hostname defines the value of hostname in the Host header of the health check request.";
          type = types.nullOr types.str;
        };
        "interval" = mkOption {
          description = "Interval defines the frequency of the health check calls for healthy targets.\nDefault: 30s";
          type = types.nullOr (types.either types.int types.str);
        };
        "method" = mkOption {
          description = "Method defines the healthcheck method.";
          type = types.nullOr types.str;
        };
        "mode" = mkOption {
          description = "Mode defines the health check mode.\nIf defined to grpc, will use the gRPC health check protocol to probe the server.\nDefault: http";
          type = types.nullOr types.str;
        };
        "path" = mkOption {
          description = "Path defines the server URL path for the health check endpoint.";
          type = types.nullOr types.str;
        };
        "port" = mkOption {
          description = "Port defines the server URL port for the health check endpoint.";
          type = types.nullOr types.int;
        };
        "scheme" = mkOption {
          description = "Scheme replaces the server URL scheme for the health check endpoint.";
          type = types.nullOr types.str;
        };
        "status" = mkOption {
          description = "Status defines the expected HTTP status code of the response to the health check request.";
          type = types.nullOr types.int;
        };
        "timeout" = mkOption {
          description = "Timeout defines the maximum duration Traefik will wait for a health check request before considering the server unhealthy.\nDefault: 5s";
          type = types.nullOr (types.either types.int types.str);
        };
        "unhealthyInterval" = mkOption {
          description = "UnhealthyInterval defines the frequency of the health check calls for unhealthy targets.\nWhen UnhealthyInterval is not defined, it defaults to the Interval value.\nDefault: 30s";
          type = types.nullOr (types.either types.int types.str);
        };
      };

      config = {
        "followRedirects" = mkOverride 1002 null;
        "headers" = mkOverride 1002 null;
        "hostname" = mkOverride 1002 null;
        "interval" = mkOverride 1002 null;
        "method" = mkOverride 1002 null;
        "mode" = mkOverride 1002 null;
        "path" = mkOverride 1002 null;
        "port" = mkOverride 1002 null;
        "scheme" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
        "timeout" = mkOverride 1002 null;
        "unhealthyInterval" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.MiddlewareSpecErrorsServicePassiveHealthCheck" = {

      options = {
        "failureWindow" = mkOption {
          description = "FailureWindow defines the time window during which the failed attempts must occur for the server to be marked as unhealthy. It also defines for how long the server will be considered unhealthy.";
          type = types.nullOr (types.either types.int types.str);
        };
        "maxFailedAttempts" = mkOption {
          description = "MaxFailedAttempts is the number of consecutive failed attempts allowed within the failure window before marking the server as unhealthy.";
          type = types.nullOr types.int;
        };
      };

      config = {
        "failureWindow" = mkOverride 1002 null;
        "maxFailedAttempts" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.MiddlewareSpecErrorsServiceResponseForwarding" = {

      options = {
        "flushInterval" = mkOption {
          description = "FlushInterval defines the interval, in milliseconds, in between flushes to the client while copying the response body.\nA negative value means to flush immediately after each write to the client.\nThis configuration is ignored when ReverseProxy recognizes a response as a streaming response;\nfor such responses, writes are flushed to the client immediately.\nDefault: 100ms";
          type = types.nullOr types.str;
        };
      };

      config = {
        "flushInterval" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.MiddlewareSpecErrorsServiceSticky" = {

      options = {
        "cookie" = mkOption {
          description = "Cookie defines the sticky cookie configuration.";
          type = types.nullOr (submoduleOf "traefik.io.v1alpha1.MiddlewareSpecErrorsServiceStickyCookie");
        };
      };

      config = {
        "cookie" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.MiddlewareSpecErrorsServiceStickyCookie" = {

      options = {
        "domain" = mkOption {
          description = "Domain defines the host to which the cookie will be sent.\nMore info: https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Set-Cookie#domaindomain-value";
          type = types.nullOr types.str;
        };
        "httpOnly" = mkOption {
          description = "HTTPOnly defines whether the cookie can be accessed by client-side APIs, such as JavaScript.";
          type = types.nullOr types.bool;
        };
        "maxAge" = mkOption {
          description = "MaxAge defines the number of seconds until the cookie expires.\nWhen set to a negative number, the cookie expires immediately.\nWhen set to zero, the cookie never expires.";
          type = types.nullOr types.int;
        };
        "name" = mkOption {
          description = "Name defines the Cookie name.";
          type = types.nullOr types.str;
        };
        "path" = mkOption {
          description = "Path defines the path that must exist in the requested URL for the browser to send the Cookie header.\nWhen not provided the cookie will be sent on every request to the domain.\nMore info: https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Set-Cookie#pathpath-value";
          type = types.nullOr types.str;
        };
        "sameSite" = mkOption {
          description = "SameSite defines the same site policy.\nMore info: https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Set-Cookie/SameSite";
          type = types.nullOr types.str;
        };
        "secure" = mkOption {
          description = "Secure defines whether the cookie can only be transmitted over an encrypted connection (i.e. HTTPS).";
          type = types.nullOr types.bool;
        };
      };

      config = {
        "domain" = mkOverride 1002 null;
        "httpOnly" = mkOverride 1002 null;
        "maxAge" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "path" = mkOverride 1002 null;
        "sameSite" = mkOverride 1002 null;
        "secure" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.MiddlewareSpecForwardAuth" = {

      options = {
        "addAuthCookiesToResponse" = mkOption {
          description = "AddAuthCookiesToResponse defines the list of cookies to copy from the authentication server response to the response.";
          type = types.nullOr (types.listOf types.str);
        };
        "address" = mkOption {
          description = "Address defines the authentication server address.";
          type = types.nullOr types.str;
        };
        "authRequestHeaders" = mkOption {
          description = "AuthRequestHeaders defines the list of the headers to copy from the request to the authentication server.\nIf not set or empty then all request headers are passed.";
          type = types.nullOr (types.listOf types.str);
        };
        "authResponseHeaders" = mkOption {
          description = "AuthResponseHeaders defines the list of headers to copy from the authentication server response and set on forwarded request, replacing any existing conflicting headers.";
          type = types.nullOr (types.listOf types.str);
        };
        "authResponseHeadersRegex" = mkOption {
          description = "AuthResponseHeadersRegex defines the regex to match headers to copy from the authentication server response and set on forwarded request, after stripping all headers that match the regex.\nMore info: https://doc.traefik.io/traefik/v3.6/reference/routing-configuration/http/middlewares/forwardauth/#authresponseheadersregex";
          type = types.nullOr types.str;
        };
        "forwardBody" = mkOption {
          description = "ForwardBody defines whether to send the request body to the authentication server.";
          type = types.nullOr types.bool;
        };
        "headerField" = mkOption {
          description = "HeaderField defines a header field to store the authenticated user.\nMore info: https://doc.traefik.io/traefik/v3.6/reference/routing-configuration/http/middlewares/forwardauth/#headerfield";
          type = types.nullOr types.str;
        };
        "maxBodySize" = mkOption {
          description = "MaxBodySize defines the maximum body size in bytes allowed to be forwarded to the authentication server.";
          type = types.nullOr types.int;
        };
        "maxResponseBodySize" = mkOption {
          description = "MaxResponseBodySize defines the maximum body size in bytes allowed in the response from the authentication server.";
          type = types.nullOr types.int;
        };
        "preserveLocationHeader" = mkOption {
          description = "PreserveLocationHeader defines whether to forward the Location header to the client as is or prefix it with the domain name of the authentication server.";
          type = types.nullOr types.bool;
        };
        "preserveRequestMethod" = mkOption {
          description = "PreserveRequestMethod defines whether to preserve the original request method while forwarding the request to the authentication server.";
          type = types.nullOr types.bool;
        };
        "tls" = mkOption {
          description = "TLS defines the configuration used to secure the connection to the authentication server.";
          type = types.nullOr (submoduleOf "traefik.io.v1alpha1.MiddlewareSpecForwardAuthTls");
        };
        "trustForwardHeader" = mkOption {
          description = "TrustForwardHeader defines whether to trust (ie: forward) all X-Forwarded-* headers.";
          type = types.nullOr types.bool;
        };
      };

      config = {
        "addAuthCookiesToResponse" = mkOverride 1002 null;
        "address" = mkOverride 1002 null;
        "authRequestHeaders" = mkOverride 1002 null;
        "authResponseHeaders" = mkOverride 1002 null;
        "authResponseHeadersRegex" = mkOverride 1002 null;
        "forwardBody" = mkOverride 1002 null;
        "headerField" = mkOverride 1002 null;
        "maxBodySize" = mkOverride 1002 null;
        "maxResponseBodySize" = mkOverride 1002 null;
        "preserveLocationHeader" = mkOverride 1002 null;
        "preserveRequestMethod" = mkOverride 1002 null;
        "tls" = mkOverride 1002 null;
        "trustForwardHeader" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.MiddlewareSpecForwardAuthTls" = {

      options = {
        "caOptional" = mkOption {
          description = "Deprecated: TLS client authentication is a server side option (see https://github.com/golang/go/blob/740a490f71d026bb7d2d13cb8fa2d6d6e0572b70/src/crypto/tls/common.go#L634).";
          type = types.nullOr types.bool;
        };
        "caSecret" = mkOption {
          description = "CASecret is the name of the referenced Kubernetes Secret containing the CA to validate the server certificate.\nThe CA certificate is extracted from key `tls.ca` or `ca.crt`.";
          type = types.nullOr types.str;
        };
        "certSecret" = mkOption {
          description = "CertSecret is the name of the referenced Kubernetes Secret containing the client certificate.\nThe client certificate is extracted from the keys `tls.crt` and `tls.key`.";
          type = types.nullOr types.str;
        };
        "insecureSkipVerify" = mkOption {
          description = "InsecureSkipVerify defines whether the server certificates should be validated.";
          type = types.nullOr types.bool;
        };
      };

      config = {
        "caOptional" = mkOverride 1002 null;
        "caSecret" = mkOverride 1002 null;
        "certSecret" = mkOverride 1002 null;
        "insecureSkipVerify" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.MiddlewareSpecGrpcWeb" = {

      options = {
        "allowOrigins" = mkOption {
          description = "AllowOrigins is a list of allowable origins.\nCan also be a wildcard origin \"*\".";
          type = types.nullOr (types.listOf types.str);
        };
      };

      config = {
        "allowOrigins" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.MiddlewareSpecHeaders" = {

      options = {
        "accessControlAllowCredentials" = mkOption {
          description = "AccessControlAllowCredentials defines whether the request can include user credentials.";
          type = types.nullOr types.bool;
        };
        "accessControlAllowHeaders" = mkOption {
          description = "AccessControlAllowHeaders defines the Access-Control-Request-Headers values sent in preflight response.";
          type = types.nullOr (types.listOf types.str);
        };
        "accessControlAllowMethods" = mkOption {
          description = "AccessControlAllowMethods defines the Access-Control-Request-Method values sent in preflight response.";
          type = types.nullOr (types.listOf types.str);
        };
        "accessControlAllowOriginList" = mkOption {
          description = "AccessControlAllowOriginList is a list of allowable origins. Can also be a wildcard origin \"*\".";
          type = types.nullOr (types.listOf types.str);
        };
        "accessControlAllowOriginListRegex" = mkOption {
          description = "AccessControlAllowOriginListRegex is a list of allowable origins written following the Regular Expression syntax (https://golang.org/pkg/regexp/).";
          type = types.nullOr (types.listOf types.str);
        };
        "accessControlExposeHeaders" = mkOption {
          description = "AccessControlExposeHeaders defines the Access-Control-Expose-Headers values sent in preflight response.";
          type = types.nullOr (types.listOf types.str);
        };
        "accessControlMaxAge" = mkOption {
          description = "AccessControlMaxAge defines the time that a preflight request may be cached.";
          type = types.nullOr types.int;
        };
        "addVaryHeader" = mkOption {
          description = "AddVaryHeader defines whether the Vary header is automatically added/updated when the AccessControlAllowOriginList is set.";
          type = types.nullOr types.bool;
        };
        "allowedHosts" = mkOption {
          description = "AllowedHosts defines the fully qualified list of allowed domain names.";
          type = types.nullOr (types.listOf types.str);
        };
        "browserXssFilter" = mkOption {
          description = "BrowserXSSFilter defines whether to add the X-XSS-Protection header with the value 1; mode=block.";
          type = types.nullOr types.bool;
        };
        "contentSecurityPolicy" = mkOption {
          description = "ContentSecurityPolicy defines the Content-Security-Policy header value.";
          type = types.nullOr types.str;
        };
        "contentSecurityPolicyReportOnly" = mkOption {
          description = "ContentSecurityPolicyReportOnly defines the Content-Security-Policy-Report-Only header value.";
          type = types.nullOr types.str;
        };
        "contentTypeNosniff" = mkOption {
          description = "ContentTypeNosniff defines whether to add the X-Content-Type-Options header with the nosniff value.";
          type = types.nullOr types.bool;
        };
        "customBrowserXSSValue" = mkOption {
          description = "CustomBrowserXSSValue defines the X-XSS-Protection header value.\nThis overrides the BrowserXssFilter option.";
          type = types.nullOr types.str;
        };
        "customFrameOptionsValue" = mkOption {
          description = "CustomFrameOptionsValue defines the X-Frame-Options header value.\nThis overrides the FrameDeny option.";
          type = types.nullOr types.str;
        };
        "customRequestHeaders" = mkOption {
          description = "CustomRequestHeaders defines the header names and values to apply to the request.";
          type = types.nullOr (types.attrsOf types.str);
        };
        "customResponseHeaders" = mkOption {
          description = "CustomResponseHeaders defines the header names and values to apply to the response.";
          type = types.nullOr (types.attrsOf types.str);
        };
        "featurePolicy" = mkOption {
          description = "Deprecated: FeaturePolicy option is deprecated, please use PermissionsPolicy instead.";
          type = types.nullOr types.str;
        };
        "forceSTSHeader" = mkOption {
          description = "ForceSTSHeader defines whether to add the STS header even when the connection is HTTP.";
          type = types.nullOr types.bool;
        };
        "frameDeny" = mkOption {
          description = "FrameDeny defines whether to add the X-Frame-Options header with the DENY value.";
          type = types.nullOr types.bool;
        };
        "hostsProxyHeaders" = mkOption {
          description = "HostsProxyHeaders defines the header keys that may hold a proxied hostname value for the request.";
          type = types.nullOr (types.listOf types.str);
        };
        "isDevelopment" = mkOption {
          description = "IsDevelopment defines whether to mitigate the unwanted effects of the AllowedHosts, SSL, and STS options when developing.\nUsually testing takes place using HTTP, not HTTPS, and on localhost, not your production domain.\nIf you would like your development environment to mimic production with complete Host blocking, SSL redirects,\nand STS headers, leave this as false.";
          type = types.nullOr types.bool;
        };
        "permissionsPolicy" = mkOption {
          description = "PermissionsPolicy defines the Permissions-Policy header value.\nThis allows sites to control browser features.";
          type = types.nullOr types.str;
        };
        "publicKey" = mkOption {
          description = "PublicKey is the public key that implements HPKP to prevent MITM attacks with forged certificates.";
          type = types.nullOr types.str;
        };
        "referrerPolicy" = mkOption {
          description = "ReferrerPolicy defines the Referrer-Policy header value.\nThis allows sites to control whether browsers forward the Referer header to other sites.";
          type = types.nullOr types.str;
        };
        "sslForceHost" = mkOption {
          description = "Deprecated: SSLForceHost option is deprecated, please use RedirectRegex instead.";
          type = types.nullOr types.bool;
        };
        "sslHost" = mkOption {
          description = "Deprecated: SSLHost option is deprecated, please use RedirectRegex instead.";
          type = types.nullOr types.str;
        };
        "sslProxyHeaders" = mkOption {
          description = "SSLProxyHeaders defines the header keys with associated values that would indicate a valid HTTPS request.\nIt can be useful when using other proxies (example: \"X-Forwarded-Proto\": \"https\").";
          type = types.nullOr (types.attrsOf types.str);
        };
        "sslRedirect" = mkOption {
          description = "Deprecated: SSLRedirect option is deprecated, please use EntryPoint redirection or RedirectScheme instead.";
          type = types.nullOr types.bool;
        };
        "sslTemporaryRedirect" = mkOption {
          description = "Deprecated: SSLTemporaryRedirect option is deprecated, please use EntryPoint redirection or RedirectScheme instead.";
          type = types.nullOr types.bool;
        };
        "stsIncludeSubdomains" = mkOption {
          description = "STSIncludeSubdomains defines whether the includeSubDomains directive is appended to the Strict-Transport-Security header.";
          type = types.nullOr types.bool;
        };
        "stsPreload" = mkOption {
          description = "STSPreload defines whether the preload flag is appended to the Strict-Transport-Security header.";
          type = types.nullOr types.bool;
        };
        "stsSeconds" = mkOption {
          description = "STSSeconds defines the max-age of the Strict-Transport-Security header.\nIf set to 0, the header is not set.";
          type = types.nullOr types.int;
        };
      };

      config = {
        "accessControlAllowCredentials" = mkOverride 1002 null;
        "accessControlAllowHeaders" = mkOverride 1002 null;
        "accessControlAllowMethods" = mkOverride 1002 null;
        "accessControlAllowOriginList" = mkOverride 1002 null;
        "accessControlAllowOriginListRegex" = mkOverride 1002 null;
        "accessControlExposeHeaders" = mkOverride 1002 null;
        "accessControlMaxAge" = mkOverride 1002 null;
        "addVaryHeader" = mkOverride 1002 null;
        "allowedHosts" = mkOverride 1002 null;
        "browserXssFilter" = mkOverride 1002 null;
        "contentSecurityPolicy" = mkOverride 1002 null;
        "contentSecurityPolicyReportOnly" = mkOverride 1002 null;
        "contentTypeNosniff" = mkOverride 1002 null;
        "customBrowserXSSValue" = mkOverride 1002 null;
        "customFrameOptionsValue" = mkOverride 1002 null;
        "customRequestHeaders" = mkOverride 1002 null;
        "customResponseHeaders" = mkOverride 1002 null;
        "featurePolicy" = mkOverride 1002 null;
        "forceSTSHeader" = mkOverride 1002 null;
        "frameDeny" = mkOverride 1002 null;
        "hostsProxyHeaders" = mkOverride 1002 null;
        "isDevelopment" = mkOverride 1002 null;
        "permissionsPolicy" = mkOverride 1002 null;
        "publicKey" = mkOverride 1002 null;
        "referrerPolicy" = mkOverride 1002 null;
        "sslForceHost" = mkOverride 1002 null;
        "sslHost" = mkOverride 1002 null;
        "sslProxyHeaders" = mkOverride 1002 null;
        "sslRedirect" = mkOverride 1002 null;
        "sslTemporaryRedirect" = mkOverride 1002 null;
        "stsIncludeSubdomains" = mkOverride 1002 null;
        "stsPreload" = mkOverride 1002 null;
        "stsSeconds" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.MiddlewareSpecInFlightReq" = {

      options = {
        "amount" = mkOption {
          description = "Amount defines the maximum amount of allowed simultaneous in-flight request.\nThe middleware responds with HTTP 429 Too Many Requests if there are already amount requests in progress (based on the same sourceCriterion strategy).";
          type = types.nullOr types.int;
        };
        "sourceCriterion" = mkOption {
          description = "SourceCriterion defines what criterion is used to group requests as originating from a common source.\nIf several strategies are defined at the same time, an error will be raised.\nIf none are set, the default is to use the requestHost.\nMore info: https://doc.traefik.io/traefik/v3.6/middlewares/http/inflightreq/#sourcecriterion";
          type = types.nullOr (submoduleOf "traefik.io.v1alpha1.MiddlewareSpecInFlightReqSourceCriterion");
        };
      };

      config = {
        "amount" = mkOverride 1002 null;
        "sourceCriterion" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.MiddlewareSpecInFlightReqSourceCriterion" = {

      options = {
        "ipStrategy" = mkOption {
          description = "IPStrategy holds the IP strategy configuration used by Traefik to determine the client IP.\nMore info: https://doc.traefik.io/traefik/v3.6/middlewares/http/ipallowlist/#ipstrategy";
          type = types.nullOr (
            submoduleOf "traefik.io.v1alpha1.MiddlewareSpecInFlightReqSourceCriterionIpStrategy"
          );
        };
        "requestHeaderName" = mkOption {
          description = "RequestHeaderName defines the name of the header used to group incoming requests.";
          type = types.nullOr types.str;
        };
        "requestHost" = mkOption {
          description = "RequestHost defines whether to consider the request Host as the source.";
          type = types.nullOr types.bool;
        };
      };

      config = {
        "ipStrategy" = mkOverride 1002 null;
        "requestHeaderName" = mkOverride 1002 null;
        "requestHost" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.MiddlewareSpecInFlightReqSourceCriterionIpStrategy" = {

      options = {
        "depth" = mkOption {
          description = "Depth tells Traefik to use the X-Forwarded-For header and take the IP located at the depth position (starting from the right).";
          type = types.nullOr types.int;
        };
        "excludedIPs" = mkOption {
          description = "ExcludedIPs configures Traefik to scan the X-Forwarded-For header and select the first IP not in the list.";
          type = types.nullOr (types.listOf types.str);
        };
        "ipv6Subnet" = mkOption {
          description = "IPv6Subnet configures Traefik to consider all IPv6 addresses from the defined subnet as originating from the same IP. Applies to RemoteAddrStrategy and DepthStrategy.";
          type = types.nullOr types.int;
        };
      };

      config = {
        "depth" = mkOverride 1002 null;
        "excludedIPs" = mkOverride 1002 null;
        "ipv6Subnet" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.MiddlewareSpecIpAllowList" = {

      options = {
        "ipStrategy" = mkOption {
          description = "IPStrategy holds the IP strategy configuration used by Traefik to determine the client IP.\nMore info: https://doc.traefik.io/traefik/v3.6/middlewares/http/ipallowlist/#ipstrategy";
          type = types.nullOr (submoduleOf "traefik.io.v1alpha1.MiddlewareSpecIpAllowListIpStrategy");
        };
        "rejectStatusCode" = mkOption {
          description = "RejectStatusCode defines the HTTP status code used for refused requests.\nIf not set, the default is 403 (Forbidden).";
          type = types.nullOr types.int;
        };
        "sourceRange" = mkOption {
          description = "SourceRange defines the set of allowed IPs (or ranges of allowed IPs by using CIDR notation).";
          type = types.nullOr (types.listOf types.str);
        };
      };

      config = {
        "ipStrategy" = mkOverride 1002 null;
        "rejectStatusCode" = mkOverride 1002 null;
        "sourceRange" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.MiddlewareSpecIpAllowListIpStrategy" = {

      options = {
        "depth" = mkOption {
          description = "Depth tells Traefik to use the X-Forwarded-For header and take the IP located at the depth position (starting from the right).";
          type = types.nullOr types.int;
        };
        "excludedIPs" = mkOption {
          description = "ExcludedIPs configures Traefik to scan the X-Forwarded-For header and select the first IP not in the list.";
          type = types.nullOr (types.listOf types.str);
        };
        "ipv6Subnet" = mkOption {
          description = "IPv6Subnet configures Traefik to consider all IPv6 addresses from the defined subnet as originating from the same IP. Applies to RemoteAddrStrategy and DepthStrategy.";
          type = types.nullOr types.int;
        };
      };

      config = {
        "depth" = mkOverride 1002 null;
        "excludedIPs" = mkOverride 1002 null;
        "ipv6Subnet" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.MiddlewareSpecIpWhiteList" = {

      options = {
        "ipStrategy" = mkOption {
          description = "IPStrategy holds the IP strategy configuration used by Traefik to determine the client IP.\nMore info: https://doc.traefik.io/traefik/v3.6/middlewares/http/ipallowlist/#ipstrategy";
          type = types.nullOr (submoduleOf "traefik.io.v1alpha1.MiddlewareSpecIpWhiteListIpStrategy");
        };
        "sourceRange" = mkOption {
          description = "SourceRange defines the set of allowed IPs (or ranges of allowed IPs by using CIDR notation). Required.";
          type = types.nullOr (types.listOf types.str);
        };
      };

      config = {
        "ipStrategy" = mkOverride 1002 null;
        "sourceRange" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.MiddlewareSpecIpWhiteListIpStrategy" = {

      options = {
        "depth" = mkOption {
          description = "Depth tells Traefik to use the X-Forwarded-For header and take the IP located at the depth position (starting from the right).";
          type = types.nullOr types.int;
        };
        "excludedIPs" = mkOption {
          description = "ExcludedIPs configures Traefik to scan the X-Forwarded-For header and select the first IP not in the list.";
          type = types.nullOr (types.listOf types.str);
        };
        "ipv6Subnet" = mkOption {
          description = "IPv6Subnet configures Traefik to consider all IPv6 addresses from the defined subnet as originating from the same IP. Applies to RemoteAddrStrategy and DepthStrategy.";
          type = types.nullOr types.int;
        };
      };

      config = {
        "depth" = mkOverride 1002 null;
        "excludedIPs" = mkOverride 1002 null;
        "ipv6Subnet" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.MiddlewareSpecPassTLSClientCert" = {

      options = {
        "info" = mkOption {
          description = "Info selects the specific client certificate details you want to add to the X-Forwarded-Tls-Client-Cert-Info header.";
          type = types.nullOr (submoduleOf "traefik.io.v1alpha1.MiddlewareSpecPassTLSClientCertInfo");
        };
        "pem" = mkOption {
          description = "PEM sets the X-Forwarded-Tls-Client-Cert header with the certificate.";
          type = types.nullOr types.bool;
        };
      };

      config = {
        "info" = mkOverride 1002 null;
        "pem" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.MiddlewareSpecPassTLSClientCertInfo" = {

      options = {
        "issuer" = mkOption {
          description = "Issuer defines the client certificate issuer details to add to the X-Forwarded-Tls-Client-Cert-Info header.";
          type = types.nullOr (submoduleOf "traefik.io.v1alpha1.MiddlewareSpecPassTLSClientCertInfoIssuer");
        };
        "notAfter" = mkOption {
          description = "NotAfter defines whether to add the Not After information from the Validity part.";
          type = types.nullOr types.bool;
        };
        "notBefore" = mkOption {
          description = "NotBefore defines whether to add the Not Before information from the Validity part.";
          type = types.nullOr types.bool;
        };
        "sans" = mkOption {
          description = "Sans defines whether to add the Subject Alternative Name information from the Subject Alternative Name part.";
          type = types.nullOr types.bool;
        };
        "serialNumber" = mkOption {
          description = "SerialNumber defines whether to add the client serialNumber information.";
          type = types.nullOr types.bool;
        };
        "subject" = mkOption {
          description = "Subject defines the client certificate subject details to add to the X-Forwarded-Tls-Client-Cert-Info header.";
          type = types.nullOr (submoduleOf "traefik.io.v1alpha1.MiddlewareSpecPassTLSClientCertInfoSubject");
        };
      };

      config = {
        "issuer" = mkOverride 1002 null;
        "notAfter" = mkOverride 1002 null;
        "notBefore" = mkOverride 1002 null;
        "sans" = mkOverride 1002 null;
        "serialNumber" = mkOverride 1002 null;
        "subject" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.MiddlewareSpecPassTLSClientCertInfoIssuer" = {

      options = {
        "commonName" = mkOption {
          description = "CommonName defines whether to add the organizationalUnit information into the issuer.";
          type = types.nullOr types.bool;
        };
        "country" = mkOption {
          description = "Country defines whether to add the country information into the issuer.";
          type = types.nullOr types.bool;
        };
        "domainComponent" = mkOption {
          description = "DomainComponent defines whether to add the domainComponent information into the issuer.";
          type = types.nullOr types.bool;
        };
        "locality" = mkOption {
          description = "Locality defines whether to add the locality information into the issuer.";
          type = types.nullOr types.bool;
        };
        "organization" = mkOption {
          description = "Organization defines whether to add the organization information into the issuer.";
          type = types.nullOr types.bool;
        };
        "province" = mkOption {
          description = "Province defines whether to add the province information into the issuer.";
          type = types.nullOr types.bool;
        };
        "serialNumber" = mkOption {
          description = "SerialNumber defines whether to add the serialNumber information into the issuer.";
          type = types.nullOr types.bool;
        };
      };

      config = {
        "commonName" = mkOverride 1002 null;
        "country" = mkOverride 1002 null;
        "domainComponent" = mkOverride 1002 null;
        "locality" = mkOverride 1002 null;
        "organization" = mkOverride 1002 null;
        "province" = mkOverride 1002 null;
        "serialNumber" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.MiddlewareSpecPassTLSClientCertInfoSubject" = {

      options = {
        "commonName" = mkOption {
          description = "CommonName defines whether to add the organizationalUnit information into the subject.";
          type = types.nullOr types.bool;
        };
        "country" = mkOption {
          description = "Country defines whether to add the country information into the subject.";
          type = types.nullOr types.bool;
        };
        "domainComponent" = mkOption {
          description = "DomainComponent defines whether to add the domainComponent information into the subject.";
          type = types.nullOr types.bool;
        };
        "locality" = mkOption {
          description = "Locality defines whether to add the locality information into the subject.";
          type = types.nullOr types.bool;
        };
        "organization" = mkOption {
          description = "Organization defines whether to add the organization information into the subject.";
          type = types.nullOr types.bool;
        };
        "organizationalUnit" = mkOption {
          description = "OrganizationalUnit defines whether to add the organizationalUnit information into the subject.";
          type = types.nullOr types.bool;
        };
        "province" = mkOption {
          description = "Province defines whether to add the province information into the subject.";
          type = types.nullOr types.bool;
        };
        "serialNumber" = mkOption {
          description = "SerialNumber defines whether to add the serialNumber information into the subject.";
          type = types.nullOr types.bool;
        };
      };

      config = {
        "commonName" = mkOverride 1002 null;
        "country" = mkOverride 1002 null;
        "domainComponent" = mkOverride 1002 null;
        "locality" = mkOverride 1002 null;
        "organization" = mkOverride 1002 null;
        "organizationalUnit" = mkOverride 1002 null;
        "province" = mkOverride 1002 null;
        "serialNumber" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.MiddlewareSpecRateLimit" = {

      options = {
        "average" = mkOption {
          description = "Average is the maximum rate, by default in requests/s, allowed for the given source.\nIt defaults to 0, which means no rate limiting.\nThe rate is actually defined by dividing Average by Period. So for a rate below 1req/s,\none needs to define a Period larger than a second.";
          type = types.nullOr types.int;
        };
        "burst" = mkOption {
          description = "Burst is the maximum number of requests allowed to arrive in the same arbitrarily small period of time.\nIt defaults to 1.";
          type = types.nullOr types.int;
        };
        "period" = mkOption {
          description = "Period, in combination with Average, defines the actual maximum rate, such as:\nr = Average / Period. It defaults to a second.";
          type = types.nullOr (types.either types.int types.str);
        };
        "redis" = mkOption {
          description = "Redis hold the configs of Redis as bucket in rate limiter.";
          type = types.nullOr (submoduleOf "traefik.io.v1alpha1.MiddlewareSpecRateLimitRedis");
        };
        "sourceCriterion" = mkOption {
          description = "SourceCriterion defines what criterion is used to group requests as originating from a common source.\nIf several strategies are defined at the same time, an error will be raised.\nIf none are set, the default is to use the request's remote address field (as an ipStrategy).";
          type = types.nullOr (submoduleOf "traefik.io.v1alpha1.MiddlewareSpecRateLimitSourceCriterion");
        };
      };

      config = {
        "average" = mkOverride 1002 null;
        "burst" = mkOverride 1002 null;
        "period" = mkOverride 1002 null;
        "redis" = mkOverride 1002 null;
        "sourceCriterion" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.MiddlewareSpecRateLimitRedis" = {

      options = {
        "db" = mkOption {
          description = "DB defines the Redis database that will be selected after connecting to the server.";
          type = types.nullOr types.int;
        };
        "dialTimeout" = mkOption {
          description = "DialTimeout sets the timeout for establishing new connections.\nDefault value is 5 seconds.";
          type = types.nullOr (types.either types.int types.str);
        };
        "endpoints" = mkOption {
          description = "Endpoints contains either a single address or a seed list of host:port addresses.\nDefault value is [\"localhost:6379\"].";
          type = types.nullOr (types.listOf types.str);
        };
        "maxActiveConns" = mkOption {
          description = "MaxActiveConns defines the maximum number of connections allocated by the pool at a given time.\nDefault value is 0, meaning there is no limit.";
          type = types.nullOr types.int;
        };
        "minIdleConns" = mkOption {
          description = "MinIdleConns defines the minimum number of idle connections.\nDefault value is 0, and idle connections are not closed by default.";
          type = types.nullOr types.int;
        };
        "poolSize" = mkOption {
          description = "PoolSize defines the initial number of socket connections.\nIf the pool runs out of available connections, additional ones will be created beyond PoolSize.\nThis can be limited using MaxActiveConns.\n// Default value is 0, meaning 10 connections per every available CPU as reported by runtime.GOMAXPROCS.";
          type = types.nullOr types.int;
        };
        "readTimeout" = mkOption {
          description = "ReadTimeout defines the timeout for socket read operations.\nDefault value is 3 seconds.";
          type = types.nullOr (types.either types.int types.str);
        };
        "secret" = mkOption {
          description = "Secret defines the name of the referenced Kubernetes Secret containing Redis credentials.";
          type = types.nullOr types.str;
        };
        "tls" = mkOption {
          description = "TLS defines TLS-specific configurations, including the CA, certificate, and key,\nwhich can be provided as a file path or file content.";
          type = types.nullOr (submoduleOf "traefik.io.v1alpha1.MiddlewareSpecRateLimitRedisTls");
        };
        "writeTimeout" = mkOption {
          description = "WriteTimeout defines the timeout for socket write operations.\nDefault value is 3 seconds.";
          type = types.nullOr (types.either types.int types.str);
        };
      };

      config = {
        "db" = mkOverride 1002 null;
        "dialTimeout" = mkOverride 1002 null;
        "endpoints" = mkOverride 1002 null;
        "maxActiveConns" = mkOverride 1002 null;
        "minIdleConns" = mkOverride 1002 null;
        "poolSize" = mkOverride 1002 null;
        "readTimeout" = mkOverride 1002 null;
        "secret" = mkOverride 1002 null;
        "tls" = mkOverride 1002 null;
        "writeTimeout" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.MiddlewareSpecRateLimitRedisTls" = {

      options = {
        "caSecret" = mkOption {
          description = "CASecret is the name of the referenced Kubernetes Secret containing the CA to validate the server certificate.\nThe CA certificate is extracted from key `tls.ca` or `ca.crt`.";
          type = types.nullOr types.str;
        };
        "certSecret" = mkOption {
          description = "CertSecret is the name of the referenced Kubernetes Secret containing the client certificate.\nThe client certificate is extracted from the keys `tls.crt` and `tls.key`.";
          type = types.nullOr types.str;
        };
        "insecureSkipVerify" = mkOption {
          description = "InsecureSkipVerify defines whether the server certificates should be validated.";
          type = types.nullOr types.bool;
        };
      };

      config = {
        "caSecret" = mkOverride 1002 null;
        "certSecret" = mkOverride 1002 null;
        "insecureSkipVerify" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.MiddlewareSpecRateLimitSourceCriterion" = {

      options = {
        "ipStrategy" = mkOption {
          description = "IPStrategy holds the IP strategy configuration used by Traefik to determine the client IP.\nMore info: https://doc.traefik.io/traefik/v3.6/middlewares/http/ipallowlist/#ipstrategy";
          type = types.nullOr (
            submoduleOf "traefik.io.v1alpha1.MiddlewareSpecRateLimitSourceCriterionIpStrategy"
          );
        };
        "requestHeaderName" = mkOption {
          description = "RequestHeaderName defines the name of the header used to group incoming requests.";
          type = types.nullOr types.str;
        };
        "requestHost" = mkOption {
          description = "RequestHost defines whether to consider the request Host as the source.";
          type = types.nullOr types.bool;
        };
      };

      config = {
        "ipStrategy" = mkOverride 1002 null;
        "requestHeaderName" = mkOverride 1002 null;
        "requestHost" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.MiddlewareSpecRateLimitSourceCriterionIpStrategy" = {

      options = {
        "depth" = mkOption {
          description = "Depth tells Traefik to use the X-Forwarded-For header and take the IP located at the depth position (starting from the right).";
          type = types.nullOr types.int;
        };
        "excludedIPs" = mkOption {
          description = "ExcludedIPs configures Traefik to scan the X-Forwarded-For header and select the first IP not in the list.";
          type = types.nullOr (types.listOf types.str);
        };
        "ipv6Subnet" = mkOption {
          description = "IPv6Subnet configures Traefik to consider all IPv6 addresses from the defined subnet as originating from the same IP. Applies to RemoteAddrStrategy and DepthStrategy.";
          type = types.nullOr types.int;
        };
      };

      config = {
        "depth" = mkOverride 1002 null;
        "excludedIPs" = mkOverride 1002 null;
        "ipv6Subnet" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.MiddlewareSpecRedirectRegex" = {

      options = {
        "permanent" = mkOption {
          description = "Permanent defines whether the redirection is permanent (308).";
          type = types.nullOr types.bool;
        };
        "regex" = mkOption {
          description = "Regex defines the regex used to match and capture elements from the request URL.";
          type = types.nullOr types.str;
        };
        "replacement" = mkOption {
          description = "Replacement defines how to modify the URL to have the new target URL.";
          type = types.nullOr types.str;
        };
      };

      config = {
        "permanent" = mkOverride 1002 null;
        "regex" = mkOverride 1002 null;
        "replacement" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.MiddlewareSpecRedirectScheme" = {

      options = {
        "permanent" = mkOption {
          description = "Permanent defines whether the redirection is permanent.\nFor HTTP GET requests a 301 is returned, otherwise a 308 is returned.";
          type = types.nullOr types.bool;
        };
        "port" = mkOption {
          description = "Port defines the port of the new URL.";
          type = types.nullOr types.str;
        };
        "scheme" = mkOption {
          description = "Scheme defines the scheme of the new URL.";
          type = types.nullOr types.str;
        };
      };

      config = {
        "permanent" = mkOverride 1002 null;
        "port" = mkOverride 1002 null;
        "scheme" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.MiddlewareSpecReplacePath" = {

      options = {
        "path" = mkOption {
          description = "Path defines the path to use as replacement in the request URL.";
          type = types.nullOr types.str;
        };
      };

      config = {
        "path" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.MiddlewareSpecReplacePathRegex" = {

      options = {
        "regex" = mkOption {
          description = "Regex defines the regular expression used to match and capture the path from the request URL.";
          type = types.nullOr types.str;
        };
        "replacement" = mkOption {
          description = "Replacement defines the replacement path format, which can include captured variables.";
          type = types.nullOr types.str;
        };
      };

      config = {
        "regex" = mkOverride 1002 null;
        "replacement" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.MiddlewareSpecRetry" = {

      options = {
        "attempts" = mkOption {
          description = "Attempts defines how many times the request should be retried.";
          type = types.nullOr types.int;
        };
        "initialInterval" = mkOption {
          description = "InitialInterval defines the first wait time in the exponential backoff series.\nThe maximum interval is calculated as twice the initialInterval.\nIf unspecified, requests will be retried immediately.\nThe value of initialInterval should be provided in seconds or as a valid duration format,\nsee https://pkg.go.dev/time#ParseDuration.";
          type = types.nullOr (types.either types.int types.str);
        };
      };

      config = {
        "attempts" = mkOverride 1002 null;
        "initialInterval" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.MiddlewareSpecStripPrefix" = {

      options = {
        "forceSlash" = mkOption {
          description = "Deprecated: ForceSlash option is deprecated, please remove any usage of this option.\nForceSlash ensures that the resulting stripped path is not the empty string, by replacing it with / when necessary.\nDefault: true.";
          type = types.nullOr types.bool;
        };
        "prefixes" = mkOption {
          description = "Prefixes defines the prefixes to strip from the request URL.";
          type = types.nullOr (types.listOf types.str);
        };
      };

      config = {
        "forceSlash" = mkOverride 1002 null;
        "prefixes" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.MiddlewareSpecStripPrefixRegex" = {

      options = {
        "regex" = mkOption {
          description = "Regex defines the regular expression to match the path prefix from the request URL.";
          type = types.nullOr (types.listOf types.str);
        };
      };

      config = {
        "regex" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.MiddlewareTCP" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object.\nServers should convert recognized schemas to the latest internal value, and\nmay reject unrecognized values.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = types.nullOr types.str;
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents.\nServers may infer this from the endpoint the client submits requests to.\nCannot be updated.\nIn CamelCase.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = types.nullOr types.str;
        };
        "metadata" = mkOption {
          description = "Standard object's metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = globalSubmoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta";
        };
        "spec" = mkOption {
          description = "MiddlewareTCPSpec defines the desired state of a MiddlewareTCP.";
          type = submoduleOf "traefik.io.v1alpha1.MiddlewareTCPSpec";
        };
      };

      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.MiddlewareTCPSpec" = {

      options = {
        "inFlightConn" = mkOption {
          description = "InFlightConn defines the InFlightConn middleware configuration.";
          type = types.nullOr (submoduleOf "traefik.io.v1alpha1.MiddlewareTCPSpecInFlightConn");
        };
        "ipAllowList" = mkOption {
          description = "IPAllowList defines the IPAllowList middleware configuration.\nThis middleware accepts/refuses connections based on the client IP.\nMore info: https://doc.traefik.io/traefik/v3.6/reference/routing-configuration/tcp/middlewares/ipallowlist/";
          type = types.nullOr (submoduleOf "traefik.io.v1alpha1.MiddlewareTCPSpecIpAllowList");
        };
        "ipWhiteList" = mkOption {
          description = "IPWhiteList defines the IPWhiteList middleware configuration.\nThis middleware accepts/refuses connections based on the client IP.\nMore info: https://doc.traefik.io/traefik/v3.6/reference/routing-configuration/tcp/middlewares/ipwhitelist/\n\nDeprecated: please use IPAllowList instead.";
          type = types.nullOr (submoduleOf "traefik.io.v1alpha1.MiddlewareTCPSpecIpWhiteList");
        };
      };

      config = {
        "inFlightConn" = mkOverride 1002 null;
        "ipAllowList" = mkOverride 1002 null;
        "ipWhiteList" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.MiddlewareTCPSpecInFlightConn" = {

      options = {
        "amount" = mkOption {
          description = "Amount defines the maximum amount of allowed simultaneous connections.\nThe middleware closes the connection if there are already amount connections opened.";
          type = types.nullOr types.int;
        };
      };

      config = {
        "amount" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.MiddlewareTCPSpecIpAllowList" = {

      options = {
        "sourceRange" = mkOption {
          description = "SourceRange defines the allowed IPs (or ranges of allowed IPs by using CIDR notation).";
          type = types.nullOr (types.listOf types.str);
        };
      };

      config = {
        "sourceRange" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.MiddlewareTCPSpecIpWhiteList" = {

      options = {
        "sourceRange" = mkOption {
          description = "SourceRange defines the allowed IPs (or ranges of allowed IPs by using CIDR notation).";
          type = types.nullOr (types.listOf types.str);
        };
      };

      config = {
        "sourceRange" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.ServersTransport" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object.\nServers should convert recognized schemas to the latest internal value, and\nmay reject unrecognized values.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = types.nullOr types.str;
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents.\nServers may infer this from the endpoint the client submits requests to.\nCannot be updated.\nIn CamelCase.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = types.nullOr types.str;
        };
        "metadata" = mkOption {
          description = "Standard object's metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = globalSubmoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta";
        };
        "spec" = mkOption {
          description = "ServersTransportSpec defines the desired state of a ServersTransport.";
          type = submoduleOf "traefik.io.v1alpha1.ServersTransportSpec";
        };
      };

      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.ServersTransportSpec" = {

      options = {
        "certificatesSecrets" = mkOption {
          description = "CertificatesSecrets defines a list of secret storing client certificates for mTLS.";
          type = types.nullOr (types.listOf types.str);
        };
        "disableHTTP2" = mkOption {
          description = "DisableHTTP2 disables HTTP/2 for connections with backend servers.";
          type = types.nullOr types.bool;
        };
        "forwardingTimeouts" = mkOption {
          description = "ForwardingTimeouts defines the timeouts for requests forwarded to the backend servers.";
          type = types.nullOr (submoduleOf "traefik.io.v1alpha1.ServersTransportSpecForwardingTimeouts");
        };
        "insecureSkipVerify" = mkOption {
          description = "InsecureSkipVerify disables SSL certificate verification.";
          type = types.nullOr types.bool;
        };
        "maxIdleConnsPerHost" = mkOption {
          description = "MaxIdleConnsPerHost controls the maximum idle (keep-alive) to keep per-host.";
          type = types.nullOr types.int;
        };
        "peerCertURI" = mkOption {
          description = "PeerCertURI defines the peer cert URI used to match against SAN URI during the peer certificate verification.";
          type = types.nullOr types.str;
        };
        "rootCAs" = mkOption {
          description = "RootCAs defines a list of CA certificate Secrets or ConfigMaps used to validate server certificates.";
          type = types.nullOr (types.listOf (submoduleOf "traefik.io.v1alpha1.ServersTransportSpecRootCAs"));
        };
        "rootCAsSecrets" = mkOption {
          description = "RootCAsSecrets defines a list of CA secret used to validate self-signed certificate.\n\nDeprecated: RootCAsSecrets is deprecated, please use the RootCAs option instead.";
          type = types.nullOr (types.listOf types.str);
        };
        "serverName" = mkOption {
          description = "ServerName defines the server name used to contact the server.";
          type = types.nullOr types.str;
        };
        "spiffe" = mkOption {
          description = "Spiffe defines the SPIFFE configuration.";
          type = types.nullOr (submoduleOf "traefik.io.v1alpha1.ServersTransportSpecSpiffe");
        };
      };

      config = {
        "certificatesSecrets" = mkOverride 1002 null;
        "disableHTTP2" = mkOverride 1002 null;
        "forwardingTimeouts" = mkOverride 1002 null;
        "insecureSkipVerify" = mkOverride 1002 null;
        "maxIdleConnsPerHost" = mkOverride 1002 null;
        "peerCertURI" = mkOverride 1002 null;
        "rootCAs" = mkOverride 1002 null;
        "rootCAsSecrets" = mkOverride 1002 null;
        "serverName" = mkOverride 1002 null;
        "spiffe" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.ServersTransportSpecForwardingTimeouts" = {

      options = {
        "dialTimeout" = mkOption {
          description = "DialTimeout is the amount of time to wait until a connection to a backend server can be established.";
          type = types.nullOr (types.either types.int types.str);
        };
        "idleConnTimeout" = mkOption {
          description = "IdleConnTimeout is the maximum period for which an idle HTTP keep-alive connection will remain open before closing itself.";
          type = types.nullOr (types.either types.int types.str);
        };
        "pingTimeout" = mkOption {
          description = "PingTimeout is the timeout after which the HTTP/2 connection will be closed if a response to ping is not received.";
          type = types.nullOr (types.either types.int types.str);
        };
        "readIdleTimeout" = mkOption {
          description = "ReadIdleTimeout is the timeout after which a health check using ping frame will be carried out if no frame is received on the HTTP/2 connection.";
          type = types.nullOr (types.either types.int types.str);
        };
        "responseHeaderTimeout" = mkOption {
          description = "ResponseHeaderTimeout is the amount of time to wait for a server's response headers after fully writing the request (including its body, if any).";
          type = types.nullOr (types.either types.int types.str);
        };
      };

      config = {
        "dialTimeout" = mkOverride 1002 null;
        "idleConnTimeout" = mkOverride 1002 null;
        "pingTimeout" = mkOverride 1002 null;
        "readIdleTimeout" = mkOverride 1002 null;
        "responseHeaderTimeout" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.ServersTransportSpecRootCAs" = {

      options = {
        "configMap" = mkOption {
          description = "ConfigMap defines the name of a ConfigMap that holds a CA certificate.\nThe referenced ConfigMap must contain a certificate under either a tls.ca or a ca.crt key.";
          type = types.nullOr types.str;
        };
        "secret" = mkOption {
          description = "Secret defines the name of a Secret that holds a CA certificate.\nThe referenced Secret must contain a certificate under either a tls.ca or a ca.crt key.";
          type = types.nullOr types.str;
        };
      };

      config = {
        "configMap" = mkOverride 1002 null;
        "secret" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.ServersTransportSpecSpiffe" = {

      options = {
        "ids" = mkOption {
          description = "IDs defines the allowed SPIFFE IDs (takes precedence over the SPIFFE TrustDomain).";
          type = types.nullOr (types.listOf types.str);
        };
        "trustDomain" = mkOption {
          description = "TrustDomain defines the allowed SPIFFE trust domain.";
          type = types.nullOr types.str;
        };
      };

      config = {
        "ids" = mkOverride 1002 null;
        "trustDomain" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.ServersTransportTCP" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object.\nServers should convert recognized schemas to the latest internal value, and\nmay reject unrecognized values.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = types.nullOr types.str;
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents.\nServers may infer this from the endpoint the client submits requests to.\nCannot be updated.\nIn CamelCase.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = types.nullOr types.str;
        };
        "metadata" = mkOption {
          description = "Standard object's metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = globalSubmoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta";
        };
        "spec" = mkOption {
          description = "ServersTransportTCPSpec defines the desired state of a ServersTransportTCP.";
          type = submoduleOf "traefik.io.v1alpha1.ServersTransportTCPSpec";
        };
      };

      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.ServersTransportTCPSpec" = {

      options = {
        "dialKeepAlive" = mkOption {
          description = "DialKeepAlive is the interval between keep-alive probes for an active network connection. If zero, keep-alive probes are sent with a default value (currently 15 seconds), if supported by the protocol and operating system. Network protocols or operating systems that do not support keep-alives ignore this field. If negative, keep-alive probes are disabled.";
          type = types.nullOr (types.either types.int types.str);
        };
        "dialTimeout" = mkOption {
          description = "DialTimeout is the amount of time to wait until a connection to a backend server can be established.";
          type = types.nullOr (types.either types.int types.str);
        };
        "proxyProtocol" = mkOption {
          description = "ProxyProtocol holds the PROXY Protocol configuration.";
          type = types.nullOr (submoduleOf "traefik.io.v1alpha1.ServersTransportTCPSpecProxyProtocol");
        };
        "terminationDelay" = mkOption {
          description = "TerminationDelay defines the delay to wait before fully terminating the connection, after one connected peer has closed its writing capability.";
          type = types.nullOr (types.either types.int types.str);
        };
        "tls" = mkOption {
          description = "TLS defines the TLS configuration";
          type = types.nullOr (submoduleOf "traefik.io.v1alpha1.ServersTransportTCPSpecTls");
        };
      };

      config = {
        "dialKeepAlive" = mkOverride 1002 null;
        "dialTimeout" = mkOverride 1002 null;
        "proxyProtocol" = mkOverride 1002 null;
        "terminationDelay" = mkOverride 1002 null;
        "tls" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.ServersTransportTCPSpecProxyProtocol" = {

      options = {
        "version" = mkOption {
          description = "Version defines the PROXY Protocol version to use.";
          type = types.nullOr types.int;
        };
      };

      config = {
        "version" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.ServersTransportTCPSpecTls" = {

      options = {
        "certificatesSecrets" = mkOption {
          description = "CertificatesSecrets defines a list of secret storing client certificates for mTLS.";
          type = types.nullOr (types.listOf types.str);
        };
        "insecureSkipVerify" = mkOption {
          description = "InsecureSkipVerify disables TLS certificate verification.";
          type = types.nullOr types.bool;
        };
        "peerCertURI" = mkOption {
          description = "MaxIdleConnsPerHost controls the maximum idle (keep-alive) to keep per-host.\nPeerCertURI defines the peer cert URI used to match against SAN URI during the peer certificate verification.";
          type = types.nullOr types.str;
        };
        "rootCAs" = mkOption {
          description = "RootCAs defines a list of CA certificate Secrets or ConfigMaps used to validate server certificates.";
          type = types.nullOr (
            types.listOf (submoduleOf "traefik.io.v1alpha1.ServersTransportTCPSpecTlsRootCAs")
          );
        };
        "rootCAsSecrets" = mkOption {
          description = "RootCAsSecrets defines a list of CA secret used to validate self-signed certificate.\n\nDeprecated: RootCAsSecrets is deprecated, please use the RootCAs option instead.";
          type = types.nullOr (types.listOf types.str);
        };
        "serverName" = mkOption {
          description = "ServerName defines the server name used to contact the server.";
          type = types.nullOr types.str;
        };
        "spiffe" = mkOption {
          description = "Spiffe defines the SPIFFE configuration.";
          type = types.nullOr (submoduleOf "traefik.io.v1alpha1.ServersTransportTCPSpecTlsSpiffe");
        };
      };

      config = {
        "certificatesSecrets" = mkOverride 1002 null;
        "insecureSkipVerify" = mkOverride 1002 null;
        "peerCertURI" = mkOverride 1002 null;
        "rootCAs" = mkOverride 1002 null;
        "rootCAsSecrets" = mkOverride 1002 null;
        "serverName" = mkOverride 1002 null;
        "spiffe" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.ServersTransportTCPSpecTlsRootCAs" = {

      options = {
        "configMap" = mkOption {
          description = "ConfigMap defines the name of a ConfigMap that holds a CA certificate.\nThe referenced ConfigMap must contain a certificate under either a tls.ca or a ca.crt key.";
          type = types.nullOr types.str;
        };
        "secret" = mkOption {
          description = "Secret defines the name of a Secret that holds a CA certificate.\nThe referenced Secret must contain a certificate under either a tls.ca or a ca.crt key.";
          type = types.nullOr types.str;
        };
      };

      config = {
        "configMap" = mkOverride 1002 null;
        "secret" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.ServersTransportTCPSpecTlsSpiffe" = {

      options = {
        "ids" = mkOption {
          description = "IDs defines the allowed SPIFFE IDs (takes precedence over the SPIFFE TrustDomain).";
          type = types.nullOr (types.listOf types.str);
        };
        "trustDomain" = mkOption {
          description = "TrustDomain defines the allowed SPIFFE trust domain.";
          type = types.nullOr types.str;
        };
      };

      config = {
        "ids" = mkOverride 1002 null;
        "trustDomain" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.TLSOption" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object.\nServers should convert recognized schemas to the latest internal value, and\nmay reject unrecognized values.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = types.nullOr types.str;
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents.\nServers may infer this from the endpoint the client submits requests to.\nCannot be updated.\nIn CamelCase.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = types.nullOr types.str;
        };
        "metadata" = mkOption {
          description = "Standard object's metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = globalSubmoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta";
        };
        "spec" = mkOption {
          description = "TLSOptionSpec defines the desired state of a TLSOption.";
          type = submoduleOf "traefik.io.v1alpha1.TLSOptionSpec";
        };
      };

      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.TLSOptionSpec" = {

      options = {
        "alpnProtocols" = mkOption {
          description = "ALPNProtocols defines the list of supported application level protocols for the TLS handshake, in order of preference.\nMore info: https://doc.traefik.io/traefik/v3.6/reference/routing-configuration/http/tls/tls-certificates/#certificates-stores#alpn-protocols";
          type = types.nullOr (types.listOf types.str);
        };
        "cipherSuites" = mkOption {
          description = "CipherSuites defines the list of supported cipher suites for TLS versions up to TLS 1.2.\nMore info: https://doc.traefik.io/traefik/v3.6/reference/routing-configuration/http/tls/tls-certificates/#certificates-stores#cipher-suites";
          type = types.nullOr (types.listOf types.str);
        };
        "clientAuth" = mkOption {
          description = "ClientAuth defines the server's policy for TLS Client Authentication.";
          type = types.nullOr (submoduleOf "traefik.io.v1alpha1.TLSOptionSpecClientAuth");
        };
        "curvePreferences" = mkOption {
          description = "CurvePreferences defines the preferred elliptic curves.\nMore info: https://doc.traefik.io/traefik/v3.6/reference/routing-configuration/http/tls/tls-certificates/#certificates-stores#curve-preferences";
          type = types.nullOr (types.listOf types.str);
        };
        "disableSessionTickets" = mkOption {
          description = "DisableSessionTickets disables TLS session resumption via session tickets.";
          type = types.nullOr types.bool;
        };
        "maxVersion" = mkOption {
          description = "MaxVersion defines the maximum TLS version that Traefik will accept.\nPossible values: VersionTLS10, VersionTLS11, VersionTLS12, VersionTLS13.\nDefault: None.";
          type = types.nullOr types.str;
        };
        "minVersion" = mkOption {
          description = "MinVersion defines the minimum TLS version that Traefik will accept.\nPossible values: VersionTLS10, VersionTLS11, VersionTLS12, VersionTLS13.\nDefault: VersionTLS10.";
          type = types.nullOr types.str;
        };
        "preferServerCipherSuites" = mkOption {
          description = "PreferServerCipherSuites defines whether the server chooses a cipher suite among his own instead of among the client's.\nIt is enabled automatically when minVersion or maxVersion is set.\n\nDeprecated: https://github.com/golang/go/issues/45430";
          type = types.nullOr types.bool;
        };
        "sniStrict" = mkOption {
          description = "SniStrict defines whether Traefik allows connections from clients connections that do not specify a server_name extension.";
          type = types.nullOr types.bool;
        };
      };

      config = {
        "alpnProtocols" = mkOverride 1002 null;
        "cipherSuites" = mkOverride 1002 null;
        "clientAuth" = mkOverride 1002 null;
        "curvePreferences" = mkOverride 1002 null;
        "disableSessionTickets" = mkOverride 1002 null;
        "maxVersion" = mkOverride 1002 null;
        "minVersion" = mkOverride 1002 null;
        "preferServerCipherSuites" = mkOverride 1002 null;
        "sniStrict" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.TLSOptionSpecClientAuth" = {

      options = {
        "clientAuthType" = mkOption {
          description = "ClientAuthType defines the client authentication type to apply.";
          type = types.nullOr types.str;
        };
        "secretNames" = mkOption {
          description = "SecretNames defines the names of the referenced Kubernetes Secret storing certificate details.";
          type = types.nullOr (types.listOf types.str);
        };
      };

      config = {
        "clientAuthType" = mkOverride 1002 null;
        "secretNames" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.TLSStore" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object.\nServers should convert recognized schemas to the latest internal value, and\nmay reject unrecognized values.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = types.nullOr types.str;
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents.\nServers may infer this from the endpoint the client submits requests to.\nCannot be updated.\nIn CamelCase.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = types.nullOr types.str;
        };
        "metadata" = mkOption {
          description = "Standard object's metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = globalSubmoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta";
        };
        "spec" = mkOption {
          description = "TLSStoreSpec defines the desired state of a TLSStore.";
          type = submoduleOf "traefik.io.v1alpha1.TLSStoreSpec";
        };
      };

      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.TLSStoreSpec" = {

      options = {
        "certificates" = mkOption {
          description = "Certificates is a list of secret names, each secret holding a key/certificate pair to add to the store.";
          type = types.nullOr (types.listOf (submoduleOf "traefik.io.v1alpha1.TLSStoreSpecCertificates"));
        };
        "defaultCertificate" = mkOption {
          description = "DefaultCertificate defines the default certificate configuration.";
          type = types.nullOr (submoduleOf "traefik.io.v1alpha1.TLSStoreSpecDefaultCertificate");
        };
        "defaultGeneratedCert" = mkOption {
          description = "DefaultGeneratedCert defines the default generated certificate configuration.";
          type = types.nullOr (submoduleOf "traefik.io.v1alpha1.TLSStoreSpecDefaultGeneratedCert");
        };
      };

      config = {
        "certificates" = mkOverride 1002 null;
        "defaultCertificate" = mkOverride 1002 null;
        "defaultGeneratedCert" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.TLSStoreSpecCertificates" = {

      options = {
        "secretName" = mkOption {
          description = "SecretName is the name of the referenced Kubernetes Secret to specify the certificate details.";
          type = types.str;
        };
      };

      config = { };

    };
    "traefik.io.v1alpha1.TLSStoreSpecDefaultCertificate" = {

      options = {
        "secretName" = mkOption {
          description = "SecretName is the name of the referenced Kubernetes Secret to specify the certificate details.";
          type = types.str;
        };
      };

      config = { };

    };
    "traefik.io.v1alpha1.TLSStoreSpecDefaultGeneratedCert" = {

      options = {
        "domain" = mkOption {
          description = "Domain is the domain definition for the DefaultCertificate.";
          type = types.nullOr (submoduleOf "traefik.io.v1alpha1.TLSStoreSpecDefaultGeneratedCertDomain");
        };
        "resolver" = mkOption {
          description = "Resolver is the name of the resolver that will be used to issue the DefaultCertificate.";
          type = types.nullOr types.str;
        };
      };

      config = {
        "domain" = mkOverride 1002 null;
        "resolver" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.TLSStoreSpecDefaultGeneratedCertDomain" = {

      options = {
        "main" = mkOption {
          description = "Main defines the main domain name.";
          type = types.nullOr types.str;
        };
        "sans" = mkOption {
          description = "SANs defines the subject alternative domain names.";
          type = types.nullOr (types.listOf types.str);
        };
      };

      config = {
        "main" = mkOverride 1002 null;
        "sans" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.TraefikService" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object.\nServers should convert recognized schemas to the latest internal value, and\nmay reject unrecognized values.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = types.nullOr types.str;
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents.\nServers may infer this from the endpoint the client submits requests to.\nCannot be updated.\nIn CamelCase.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = types.nullOr types.str;
        };
        "metadata" = mkOption {
          description = "Standard object's metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = globalSubmoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta";
        };
        "spec" = mkOption {
          description = "TraefikServiceSpec defines the desired state of a TraefikService.";
          type = submoduleOf "traefik.io.v1alpha1.TraefikServiceSpec";
        };
      };

      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.TraefikServiceSpec" = {

      options = {
        "highestRandomWeight" = mkOption {
          description = "HighestRandomWeight defines the highest random weight service configuration.";
          type = types.nullOr (submoduleOf "traefik.io.v1alpha1.TraefikServiceSpecHighestRandomWeight");
        };
        "mirroring" = mkOption {
          description = "Mirroring defines the Mirroring service configuration.";
          type = types.nullOr (submoduleOf "traefik.io.v1alpha1.TraefikServiceSpecMirroring");
        };
        "weighted" = mkOption {
          description = "Weighted defines the Weighted Round Robin configuration.";
          type = types.nullOr (submoduleOf "traefik.io.v1alpha1.TraefikServiceSpecWeighted");
        };
      };

      config = {
        "highestRandomWeight" = mkOverride 1002 null;
        "mirroring" = mkOverride 1002 null;
        "weighted" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.TraefikServiceSpecHighestRandomWeight" = {

      options = {
        "services" = mkOption {
          description = "Services defines the list of Kubernetes Service and/or TraefikService to load-balance, with weight.";
          type = types.nullOr (
            coerceAttrsOfSubmodulesToListByKey
              "traefik.io.v1alpha1.TraefikServiceSpecHighestRandomWeightServices"
              "name"
              [ ]
          );
          apply = attrsToList;
        };
      };

      config = {
        "services" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.TraefikServiceSpecHighestRandomWeightServices" = {

      options = {
        "healthCheck" = mkOption {
          description = "Healthcheck defines health checks for ExternalName services.";
          type = types.nullOr (
            submoduleOf "traefik.io.v1alpha1.TraefikServiceSpecHighestRandomWeightServicesHealthCheck"
          );
        };
        "kind" = mkOption {
          description = "Kind defines the kind of the Service.";
          type = types.nullOr types.str;
        };
        "name" = mkOption {
          description = "Name defines the name of the referenced Kubernetes Service or TraefikService.\nThe differentiation between the two is specified in the Kind field.";
          type = types.str;
        };
        "namespace" = mkOption {
          description = "Namespace defines the namespace of the referenced Kubernetes Service or TraefikService.";
          type = types.nullOr types.str;
        };
        "nativeLB" = mkOption {
          description = "NativeLB controls, when creating the load-balancer,\nwhether the LB's children are directly the pods IPs or if the only child is the Kubernetes Service clusterIP.\nThe Kubernetes Service itself does load-balance to the pods.\nBy default, NativeLB is false.";
          type = types.nullOr types.bool;
        };
        "nodePortLB" = mkOption {
          description = "NodePortLB controls, when creating the load-balancer,\nwhether the LB's children are directly the nodes internal IPs using the nodePort when the service type is NodePort.\nIt allows services to be reachable when Traefik runs externally from the Kubernetes cluster but within the same network of the nodes.\nBy default, NodePortLB is false.";
          type = types.nullOr types.bool;
        };
        "passHostHeader" = mkOption {
          description = "PassHostHeader defines whether the client Host header is forwarded to the upstream Kubernetes Service.\nBy default, passHostHeader is true.";
          type = types.nullOr types.bool;
        };
        "passiveHealthCheck" = mkOption {
          description = "PassiveHealthCheck defines passive health checks for ExternalName services.";
          type = types.nullOr (
            submoduleOf "traefik.io.v1alpha1.TraefikServiceSpecHighestRandomWeightServicesPassiveHealthCheck"
          );
        };
        "port" = mkOption {
          description = "Port defines the port of a Kubernetes Service.\nThis can be a reference to a named port.";
          type = types.nullOr (types.either types.int types.str);
        };
        "responseForwarding" = mkOption {
          description = "ResponseForwarding defines how Traefik forwards the response from the upstream Kubernetes Service to the client.";
          type = types.nullOr (
            submoduleOf "traefik.io.v1alpha1.TraefikServiceSpecHighestRandomWeightServicesResponseForwarding"
          );
        };
        "scheme" = mkOption {
          description = "Scheme defines the scheme to use for the request to the upstream Kubernetes Service.\nIt defaults to https when Kubernetes Service port is 443, http otherwise.";
          type = types.nullOr types.str;
        };
        "serversTransport" = mkOption {
          description = "ServersTransport defines the name of ServersTransport resource to use.\nIt allows to configure the transport between Traefik and your servers.\nCan only be used on a Kubernetes Service.";
          type = types.nullOr types.str;
        };
        "sticky" = mkOption {
          description = "Sticky defines the sticky sessions configuration.\nMore info: https://doc.traefik.io/traefik/v3.6/reference/routing-configuration/http/load-balancing/service/#sticky-sessions";
          type = types.nullOr (
            submoduleOf "traefik.io.v1alpha1.TraefikServiceSpecHighestRandomWeightServicesSticky"
          );
        };
        "strategy" = mkOption {
          description = "Strategy defines the load balancing strategy between the servers.\nSupported values are: wrr (Weighed round-robin), p2c (Power of two choices), hrw (Highest Random Weight), and leasttime (Least-Time).\nRoundRobin value is deprecated and supported for backward compatibility.";
          type = types.nullOr types.str;
        };
        "weight" = mkOption {
          description = "Weight defines the weight and should only be specified when Name references a TraefikService object\n(and to be precise, one that embeds a Weighted Round Robin).";
          type = types.nullOr types.int;
        };
      };

      config = {
        "healthCheck" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
        "nativeLB" = mkOverride 1002 null;
        "nodePortLB" = mkOverride 1002 null;
        "passHostHeader" = mkOverride 1002 null;
        "passiveHealthCheck" = mkOverride 1002 null;
        "port" = mkOverride 1002 null;
        "responseForwarding" = mkOverride 1002 null;
        "scheme" = mkOverride 1002 null;
        "serversTransport" = mkOverride 1002 null;
        "sticky" = mkOverride 1002 null;
        "strategy" = mkOverride 1002 null;
        "weight" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.TraefikServiceSpecHighestRandomWeightServicesHealthCheck" = {

      options = {
        "followRedirects" = mkOption {
          description = "FollowRedirects defines whether redirects should be followed during the health check calls.\nDefault: true";
          type = types.nullOr types.bool;
        };
        "headers" = mkOption {
          description = "Headers defines custom headers to be sent to the health check endpoint.";
          type = types.nullOr (types.attrsOf types.str);
        };
        "hostname" = mkOption {
          description = "Hostname defines the value of hostname in the Host header of the health check request.";
          type = types.nullOr types.str;
        };
        "interval" = mkOption {
          description = "Interval defines the frequency of the health check calls for healthy targets.\nDefault: 30s";
          type = types.nullOr (types.either types.int types.str);
        };
        "method" = mkOption {
          description = "Method defines the healthcheck method.";
          type = types.nullOr types.str;
        };
        "mode" = mkOption {
          description = "Mode defines the health check mode.\nIf defined to grpc, will use the gRPC health check protocol to probe the server.\nDefault: http";
          type = types.nullOr types.str;
        };
        "path" = mkOption {
          description = "Path defines the server URL path for the health check endpoint.";
          type = types.nullOr types.str;
        };
        "port" = mkOption {
          description = "Port defines the server URL port for the health check endpoint.";
          type = types.nullOr types.int;
        };
        "scheme" = mkOption {
          description = "Scheme replaces the server URL scheme for the health check endpoint.";
          type = types.nullOr types.str;
        };
        "status" = mkOption {
          description = "Status defines the expected HTTP status code of the response to the health check request.";
          type = types.nullOr types.int;
        };
        "timeout" = mkOption {
          description = "Timeout defines the maximum duration Traefik will wait for a health check request before considering the server unhealthy.\nDefault: 5s";
          type = types.nullOr (types.either types.int types.str);
        };
        "unhealthyInterval" = mkOption {
          description = "UnhealthyInterval defines the frequency of the health check calls for unhealthy targets.\nWhen UnhealthyInterval is not defined, it defaults to the Interval value.\nDefault: 30s";
          type = types.nullOr (types.either types.int types.str);
        };
      };

      config = {
        "followRedirects" = mkOverride 1002 null;
        "headers" = mkOverride 1002 null;
        "hostname" = mkOverride 1002 null;
        "interval" = mkOverride 1002 null;
        "method" = mkOverride 1002 null;
        "mode" = mkOverride 1002 null;
        "path" = mkOverride 1002 null;
        "port" = mkOverride 1002 null;
        "scheme" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
        "timeout" = mkOverride 1002 null;
        "unhealthyInterval" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.TraefikServiceSpecHighestRandomWeightServicesPassiveHealthCheck" = {

      options = {
        "failureWindow" = mkOption {
          description = "FailureWindow defines the time window during which the failed attempts must occur for the server to be marked as unhealthy. It also defines for how long the server will be considered unhealthy.";
          type = types.nullOr (types.either types.int types.str);
        };
        "maxFailedAttempts" = mkOption {
          description = "MaxFailedAttempts is the number of consecutive failed attempts allowed within the failure window before marking the server as unhealthy.";
          type = types.nullOr types.int;
        };
      };

      config = {
        "failureWindow" = mkOverride 1002 null;
        "maxFailedAttempts" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.TraefikServiceSpecHighestRandomWeightServicesResponseForwarding" = {

      options = {
        "flushInterval" = mkOption {
          description = "FlushInterval defines the interval, in milliseconds, in between flushes to the client while copying the response body.\nA negative value means to flush immediately after each write to the client.\nThis configuration is ignored when ReverseProxy recognizes a response as a streaming response;\nfor such responses, writes are flushed to the client immediately.\nDefault: 100ms";
          type = types.nullOr types.str;
        };
      };

      config = {
        "flushInterval" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.TraefikServiceSpecHighestRandomWeightServicesSticky" = {

      options = {
        "cookie" = mkOption {
          description = "Cookie defines the sticky cookie configuration.";
          type = types.nullOr (
            submoduleOf "traefik.io.v1alpha1.TraefikServiceSpecHighestRandomWeightServicesStickyCookie"
          );
        };
      };

      config = {
        "cookie" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.TraefikServiceSpecHighestRandomWeightServicesStickyCookie" = {

      options = {
        "domain" = mkOption {
          description = "Domain defines the host to which the cookie will be sent.\nMore info: https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Set-Cookie#domaindomain-value";
          type = types.nullOr types.str;
        };
        "httpOnly" = mkOption {
          description = "HTTPOnly defines whether the cookie can be accessed by client-side APIs, such as JavaScript.";
          type = types.nullOr types.bool;
        };
        "maxAge" = mkOption {
          description = "MaxAge defines the number of seconds until the cookie expires.\nWhen set to a negative number, the cookie expires immediately.\nWhen set to zero, the cookie never expires.";
          type = types.nullOr types.int;
        };
        "name" = mkOption {
          description = "Name defines the Cookie name.";
          type = types.nullOr types.str;
        };
        "path" = mkOption {
          description = "Path defines the path that must exist in the requested URL for the browser to send the Cookie header.\nWhen not provided the cookie will be sent on every request to the domain.\nMore info: https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Set-Cookie#pathpath-value";
          type = types.nullOr types.str;
        };
        "sameSite" = mkOption {
          description = "SameSite defines the same site policy.\nMore info: https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Set-Cookie/SameSite";
          type = types.nullOr types.str;
        };
        "secure" = mkOption {
          description = "Secure defines whether the cookie can only be transmitted over an encrypted connection (i.e. HTTPS).";
          type = types.nullOr types.bool;
        };
      };

      config = {
        "domain" = mkOverride 1002 null;
        "httpOnly" = mkOverride 1002 null;
        "maxAge" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "path" = mkOverride 1002 null;
        "sameSite" = mkOverride 1002 null;
        "secure" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.TraefikServiceSpecMirroring" = {

      options = {
        "healthCheck" = mkOption {
          description = "Healthcheck defines health checks for ExternalName services.";
          type = types.nullOr (submoduleOf "traefik.io.v1alpha1.TraefikServiceSpecMirroringHealthCheck");
        };
        "kind" = mkOption {
          description = "Kind defines the kind of the Service.";
          type = types.nullOr types.str;
        };
        "maxBodySize" = mkOption {
          description = "MaxBodySize defines the maximum size allowed for the body of the request.\nIf the body is larger, the request is not mirrored.\nDefault value is -1, which means unlimited size.";
          type = types.nullOr types.int;
        };
        "mirrorBody" = mkOption {
          description = "MirrorBody defines whether the body of the request should be mirrored.\nDefault value is true.";
          type = types.nullOr types.bool;
        };
        "mirrors" = mkOption {
          description = "Mirrors defines the list of mirrors where Traefik will duplicate the traffic.";
          type = types.nullOr (
            coerceAttrsOfSubmodulesToListByKey "traefik.io.v1alpha1.TraefikServiceSpecMirroringMirrors" "name"
              [ ]
          );
          apply = attrsToList;
        };
        "name" = mkOption {
          description = "Name defines the name of the referenced Kubernetes Service or TraefikService.\nThe differentiation between the two is specified in the Kind field.";
          type = types.str;
        };
        "namespace" = mkOption {
          description = "Namespace defines the namespace of the referenced Kubernetes Service or TraefikService.";
          type = types.nullOr types.str;
        };
        "nativeLB" = mkOption {
          description = "NativeLB controls, when creating the load-balancer,\nwhether the LB's children are directly the pods IPs or if the only child is the Kubernetes Service clusterIP.\nThe Kubernetes Service itself does load-balance to the pods.\nBy default, NativeLB is false.";
          type = types.nullOr types.bool;
        };
        "nodePortLB" = mkOption {
          description = "NodePortLB controls, when creating the load-balancer,\nwhether the LB's children are directly the nodes internal IPs using the nodePort when the service type is NodePort.\nIt allows services to be reachable when Traefik runs externally from the Kubernetes cluster but within the same network of the nodes.\nBy default, NodePortLB is false.";
          type = types.nullOr types.bool;
        };
        "passHostHeader" = mkOption {
          description = "PassHostHeader defines whether the client Host header is forwarded to the upstream Kubernetes Service.\nBy default, passHostHeader is true.";
          type = types.nullOr types.bool;
        };
        "passiveHealthCheck" = mkOption {
          description = "PassiveHealthCheck defines passive health checks for ExternalName services.";
          type = types.nullOr (
            submoduleOf "traefik.io.v1alpha1.TraefikServiceSpecMirroringPassiveHealthCheck"
          );
        };
        "port" = mkOption {
          description = "Port defines the port of a Kubernetes Service.\nThis can be a reference to a named port.";
          type = types.nullOr (types.either types.int types.str);
        };
        "responseForwarding" = mkOption {
          description = "ResponseForwarding defines how Traefik forwards the response from the upstream Kubernetes Service to the client.";
          type = types.nullOr (
            submoduleOf "traefik.io.v1alpha1.TraefikServiceSpecMirroringResponseForwarding"
          );
        };
        "scheme" = mkOption {
          description = "Scheme defines the scheme to use for the request to the upstream Kubernetes Service.\nIt defaults to https when Kubernetes Service port is 443, http otherwise.";
          type = types.nullOr types.str;
        };
        "serversTransport" = mkOption {
          description = "ServersTransport defines the name of ServersTransport resource to use.\nIt allows to configure the transport between Traefik and your servers.\nCan only be used on a Kubernetes Service.";
          type = types.nullOr types.str;
        };
        "sticky" = mkOption {
          description = "Sticky defines the sticky sessions configuration.\nMore info: https://doc.traefik.io/traefik/v3.6/reference/routing-configuration/http/load-balancing/service/#sticky-sessions";
          type = types.nullOr (submoduleOf "traefik.io.v1alpha1.TraefikServiceSpecMirroringSticky");
        };
        "strategy" = mkOption {
          description = "Strategy defines the load balancing strategy between the servers.\nSupported values are: wrr (Weighed round-robin), p2c (Power of two choices), hrw (Highest Random Weight), and leasttime (Least-Time).\nRoundRobin value is deprecated and supported for backward compatibility.";
          type = types.nullOr types.str;
        };
        "weight" = mkOption {
          description = "Weight defines the weight and should only be specified when Name references a TraefikService object\n(and to be precise, one that embeds a Weighted Round Robin).";
          type = types.nullOr types.int;
        };
      };

      config = {
        "healthCheck" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "maxBodySize" = mkOverride 1002 null;
        "mirrorBody" = mkOverride 1002 null;
        "mirrors" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
        "nativeLB" = mkOverride 1002 null;
        "nodePortLB" = mkOverride 1002 null;
        "passHostHeader" = mkOverride 1002 null;
        "passiveHealthCheck" = mkOverride 1002 null;
        "port" = mkOverride 1002 null;
        "responseForwarding" = mkOverride 1002 null;
        "scheme" = mkOverride 1002 null;
        "serversTransport" = mkOverride 1002 null;
        "sticky" = mkOverride 1002 null;
        "strategy" = mkOverride 1002 null;
        "weight" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.TraefikServiceSpecMirroringHealthCheck" = {

      options = {
        "followRedirects" = mkOption {
          description = "FollowRedirects defines whether redirects should be followed during the health check calls.\nDefault: true";
          type = types.nullOr types.bool;
        };
        "headers" = mkOption {
          description = "Headers defines custom headers to be sent to the health check endpoint.";
          type = types.nullOr (types.attrsOf types.str);
        };
        "hostname" = mkOption {
          description = "Hostname defines the value of hostname in the Host header of the health check request.";
          type = types.nullOr types.str;
        };
        "interval" = mkOption {
          description = "Interval defines the frequency of the health check calls for healthy targets.\nDefault: 30s";
          type = types.nullOr (types.either types.int types.str);
        };
        "method" = mkOption {
          description = "Method defines the healthcheck method.";
          type = types.nullOr types.str;
        };
        "mode" = mkOption {
          description = "Mode defines the health check mode.\nIf defined to grpc, will use the gRPC health check protocol to probe the server.\nDefault: http";
          type = types.nullOr types.str;
        };
        "path" = mkOption {
          description = "Path defines the server URL path for the health check endpoint.";
          type = types.nullOr types.str;
        };
        "port" = mkOption {
          description = "Port defines the server URL port for the health check endpoint.";
          type = types.nullOr types.int;
        };
        "scheme" = mkOption {
          description = "Scheme replaces the server URL scheme for the health check endpoint.";
          type = types.nullOr types.str;
        };
        "status" = mkOption {
          description = "Status defines the expected HTTP status code of the response to the health check request.";
          type = types.nullOr types.int;
        };
        "timeout" = mkOption {
          description = "Timeout defines the maximum duration Traefik will wait for a health check request before considering the server unhealthy.\nDefault: 5s";
          type = types.nullOr (types.either types.int types.str);
        };
        "unhealthyInterval" = mkOption {
          description = "UnhealthyInterval defines the frequency of the health check calls for unhealthy targets.\nWhen UnhealthyInterval is not defined, it defaults to the Interval value.\nDefault: 30s";
          type = types.nullOr (types.either types.int types.str);
        };
      };

      config = {
        "followRedirects" = mkOverride 1002 null;
        "headers" = mkOverride 1002 null;
        "hostname" = mkOverride 1002 null;
        "interval" = mkOverride 1002 null;
        "method" = mkOverride 1002 null;
        "mode" = mkOverride 1002 null;
        "path" = mkOverride 1002 null;
        "port" = mkOverride 1002 null;
        "scheme" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
        "timeout" = mkOverride 1002 null;
        "unhealthyInterval" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.TraefikServiceSpecMirroringMirrors" = {

      options = {
        "healthCheck" = mkOption {
          description = "Healthcheck defines health checks for ExternalName services.";
          type = types.nullOr (
            submoduleOf "traefik.io.v1alpha1.TraefikServiceSpecMirroringMirrorsHealthCheck"
          );
        };
        "kind" = mkOption {
          description = "Kind defines the kind of the Service.";
          type = types.nullOr types.str;
        };
        "name" = mkOption {
          description = "Name defines the name of the referenced Kubernetes Service or TraefikService.\nThe differentiation between the two is specified in the Kind field.";
          type = types.str;
        };
        "namespace" = mkOption {
          description = "Namespace defines the namespace of the referenced Kubernetes Service or TraefikService.";
          type = types.nullOr types.str;
        };
        "nativeLB" = mkOption {
          description = "NativeLB controls, when creating the load-balancer,\nwhether the LB's children are directly the pods IPs or if the only child is the Kubernetes Service clusterIP.\nThe Kubernetes Service itself does load-balance to the pods.\nBy default, NativeLB is false.";
          type = types.nullOr types.bool;
        };
        "nodePortLB" = mkOption {
          description = "NodePortLB controls, when creating the load-balancer,\nwhether the LB's children are directly the nodes internal IPs using the nodePort when the service type is NodePort.\nIt allows services to be reachable when Traefik runs externally from the Kubernetes cluster but within the same network of the nodes.\nBy default, NodePortLB is false.";
          type = types.nullOr types.bool;
        };
        "passHostHeader" = mkOption {
          description = "PassHostHeader defines whether the client Host header is forwarded to the upstream Kubernetes Service.\nBy default, passHostHeader is true.";
          type = types.nullOr types.bool;
        };
        "passiveHealthCheck" = mkOption {
          description = "PassiveHealthCheck defines passive health checks for ExternalName services.";
          type = types.nullOr (
            submoduleOf "traefik.io.v1alpha1.TraefikServiceSpecMirroringMirrorsPassiveHealthCheck"
          );
        };
        "percent" = mkOption {
          description = "Percent defines the part of the traffic to mirror.\nSupported values: 0 to 100.";
          type = types.nullOr types.int;
        };
        "port" = mkOption {
          description = "Port defines the port of a Kubernetes Service.\nThis can be a reference to a named port.";
          type = types.nullOr (types.either types.int types.str);
        };
        "responseForwarding" = mkOption {
          description = "ResponseForwarding defines how Traefik forwards the response from the upstream Kubernetes Service to the client.";
          type = types.nullOr (
            submoduleOf "traefik.io.v1alpha1.TraefikServiceSpecMirroringMirrorsResponseForwarding"
          );
        };
        "scheme" = mkOption {
          description = "Scheme defines the scheme to use for the request to the upstream Kubernetes Service.\nIt defaults to https when Kubernetes Service port is 443, http otherwise.";
          type = types.nullOr types.str;
        };
        "serversTransport" = mkOption {
          description = "ServersTransport defines the name of ServersTransport resource to use.\nIt allows to configure the transport between Traefik and your servers.\nCan only be used on a Kubernetes Service.";
          type = types.nullOr types.str;
        };
        "sticky" = mkOption {
          description = "Sticky defines the sticky sessions configuration.\nMore info: https://doc.traefik.io/traefik/v3.6/reference/routing-configuration/http/load-balancing/service/#sticky-sessions";
          type = types.nullOr (submoduleOf "traefik.io.v1alpha1.TraefikServiceSpecMirroringMirrorsSticky");
        };
        "strategy" = mkOption {
          description = "Strategy defines the load balancing strategy between the servers.\nSupported values are: wrr (Weighed round-robin), p2c (Power of two choices), hrw (Highest Random Weight), and leasttime (Least-Time).\nRoundRobin value is deprecated and supported for backward compatibility.";
          type = types.nullOr types.str;
        };
        "weight" = mkOption {
          description = "Weight defines the weight and should only be specified when Name references a TraefikService object\n(and to be precise, one that embeds a Weighted Round Robin).";
          type = types.nullOr types.int;
        };
      };

      config = {
        "healthCheck" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
        "nativeLB" = mkOverride 1002 null;
        "nodePortLB" = mkOverride 1002 null;
        "passHostHeader" = mkOverride 1002 null;
        "passiveHealthCheck" = mkOverride 1002 null;
        "percent" = mkOverride 1002 null;
        "port" = mkOverride 1002 null;
        "responseForwarding" = mkOverride 1002 null;
        "scheme" = mkOverride 1002 null;
        "serversTransport" = mkOverride 1002 null;
        "sticky" = mkOverride 1002 null;
        "strategy" = mkOverride 1002 null;
        "weight" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.TraefikServiceSpecMirroringMirrorsHealthCheck" = {

      options = {
        "followRedirects" = mkOption {
          description = "FollowRedirects defines whether redirects should be followed during the health check calls.\nDefault: true";
          type = types.nullOr types.bool;
        };
        "headers" = mkOption {
          description = "Headers defines custom headers to be sent to the health check endpoint.";
          type = types.nullOr (types.attrsOf types.str);
        };
        "hostname" = mkOption {
          description = "Hostname defines the value of hostname in the Host header of the health check request.";
          type = types.nullOr types.str;
        };
        "interval" = mkOption {
          description = "Interval defines the frequency of the health check calls for healthy targets.\nDefault: 30s";
          type = types.nullOr (types.either types.int types.str);
        };
        "method" = mkOption {
          description = "Method defines the healthcheck method.";
          type = types.nullOr types.str;
        };
        "mode" = mkOption {
          description = "Mode defines the health check mode.\nIf defined to grpc, will use the gRPC health check protocol to probe the server.\nDefault: http";
          type = types.nullOr types.str;
        };
        "path" = mkOption {
          description = "Path defines the server URL path for the health check endpoint.";
          type = types.nullOr types.str;
        };
        "port" = mkOption {
          description = "Port defines the server URL port for the health check endpoint.";
          type = types.nullOr types.int;
        };
        "scheme" = mkOption {
          description = "Scheme replaces the server URL scheme for the health check endpoint.";
          type = types.nullOr types.str;
        };
        "status" = mkOption {
          description = "Status defines the expected HTTP status code of the response to the health check request.";
          type = types.nullOr types.int;
        };
        "timeout" = mkOption {
          description = "Timeout defines the maximum duration Traefik will wait for a health check request before considering the server unhealthy.\nDefault: 5s";
          type = types.nullOr (types.either types.int types.str);
        };
        "unhealthyInterval" = mkOption {
          description = "UnhealthyInterval defines the frequency of the health check calls for unhealthy targets.\nWhen UnhealthyInterval is not defined, it defaults to the Interval value.\nDefault: 30s";
          type = types.nullOr (types.either types.int types.str);
        };
      };

      config = {
        "followRedirects" = mkOverride 1002 null;
        "headers" = mkOverride 1002 null;
        "hostname" = mkOverride 1002 null;
        "interval" = mkOverride 1002 null;
        "method" = mkOverride 1002 null;
        "mode" = mkOverride 1002 null;
        "path" = mkOverride 1002 null;
        "port" = mkOverride 1002 null;
        "scheme" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
        "timeout" = mkOverride 1002 null;
        "unhealthyInterval" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.TraefikServiceSpecMirroringMirrorsPassiveHealthCheck" = {

      options = {
        "failureWindow" = mkOption {
          description = "FailureWindow defines the time window during which the failed attempts must occur for the server to be marked as unhealthy. It also defines for how long the server will be considered unhealthy.";
          type = types.nullOr (types.either types.int types.str);
        };
        "maxFailedAttempts" = mkOption {
          description = "MaxFailedAttempts is the number of consecutive failed attempts allowed within the failure window before marking the server as unhealthy.";
          type = types.nullOr types.int;
        };
      };

      config = {
        "failureWindow" = mkOverride 1002 null;
        "maxFailedAttempts" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.TraefikServiceSpecMirroringMirrorsResponseForwarding" = {

      options = {
        "flushInterval" = mkOption {
          description = "FlushInterval defines the interval, in milliseconds, in between flushes to the client while copying the response body.\nA negative value means to flush immediately after each write to the client.\nThis configuration is ignored when ReverseProxy recognizes a response as a streaming response;\nfor such responses, writes are flushed to the client immediately.\nDefault: 100ms";
          type = types.nullOr types.str;
        };
      };

      config = {
        "flushInterval" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.TraefikServiceSpecMirroringMirrorsSticky" = {

      options = {
        "cookie" = mkOption {
          description = "Cookie defines the sticky cookie configuration.";
          type = types.nullOr (
            submoduleOf "traefik.io.v1alpha1.TraefikServiceSpecMirroringMirrorsStickyCookie"
          );
        };
      };

      config = {
        "cookie" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.TraefikServiceSpecMirroringMirrorsStickyCookie" = {

      options = {
        "domain" = mkOption {
          description = "Domain defines the host to which the cookie will be sent.\nMore info: https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Set-Cookie#domaindomain-value";
          type = types.nullOr types.str;
        };
        "httpOnly" = mkOption {
          description = "HTTPOnly defines whether the cookie can be accessed by client-side APIs, such as JavaScript.";
          type = types.nullOr types.bool;
        };
        "maxAge" = mkOption {
          description = "MaxAge defines the number of seconds until the cookie expires.\nWhen set to a negative number, the cookie expires immediately.\nWhen set to zero, the cookie never expires.";
          type = types.nullOr types.int;
        };
        "name" = mkOption {
          description = "Name defines the Cookie name.";
          type = types.nullOr types.str;
        };
        "path" = mkOption {
          description = "Path defines the path that must exist in the requested URL for the browser to send the Cookie header.\nWhen not provided the cookie will be sent on every request to the domain.\nMore info: https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Set-Cookie#pathpath-value";
          type = types.nullOr types.str;
        };
        "sameSite" = mkOption {
          description = "SameSite defines the same site policy.\nMore info: https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Set-Cookie/SameSite";
          type = types.nullOr types.str;
        };
        "secure" = mkOption {
          description = "Secure defines whether the cookie can only be transmitted over an encrypted connection (i.e. HTTPS).";
          type = types.nullOr types.bool;
        };
      };

      config = {
        "domain" = mkOverride 1002 null;
        "httpOnly" = mkOverride 1002 null;
        "maxAge" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "path" = mkOverride 1002 null;
        "sameSite" = mkOverride 1002 null;
        "secure" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.TraefikServiceSpecMirroringPassiveHealthCheck" = {

      options = {
        "failureWindow" = mkOption {
          description = "FailureWindow defines the time window during which the failed attempts must occur for the server to be marked as unhealthy. It also defines for how long the server will be considered unhealthy.";
          type = types.nullOr (types.either types.int types.str);
        };
        "maxFailedAttempts" = mkOption {
          description = "MaxFailedAttempts is the number of consecutive failed attempts allowed within the failure window before marking the server as unhealthy.";
          type = types.nullOr types.int;
        };
      };

      config = {
        "failureWindow" = mkOverride 1002 null;
        "maxFailedAttempts" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.TraefikServiceSpecMirroringResponseForwarding" = {

      options = {
        "flushInterval" = mkOption {
          description = "FlushInterval defines the interval, in milliseconds, in between flushes to the client while copying the response body.\nA negative value means to flush immediately after each write to the client.\nThis configuration is ignored when ReverseProxy recognizes a response as a streaming response;\nfor such responses, writes are flushed to the client immediately.\nDefault: 100ms";
          type = types.nullOr types.str;
        };
      };

      config = {
        "flushInterval" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.TraefikServiceSpecMirroringSticky" = {

      options = {
        "cookie" = mkOption {
          description = "Cookie defines the sticky cookie configuration.";
          type = types.nullOr (submoduleOf "traefik.io.v1alpha1.TraefikServiceSpecMirroringStickyCookie");
        };
      };

      config = {
        "cookie" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.TraefikServiceSpecMirroringStickyCookie" = {

      options = {
        "domain" = mkOption {
          description = "Domain defines the host to which the cookie will be sent.\nMore info: https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Set-Cookie#domaindomain-value";
          type = types.nullOr types.str;
        };
        "httpOnly" = mkOption {
          description = "HTTPOnly defines whether the cookie can be accessed by client-side APIs, such as JavaScript.";
          type = types.nullOr types.bool;
        };
        "maxAge" = mkOption {
          description = "MaxAge defines the number of seconds until the cookie expires.\nWhen set to a negative number, the cookie expires immediately.\nWhen set to zero, the cookie never expires.";
          type = types.nullOr types.int;
        };
        "name" = mkOption {
          description = "Name defines the Cookie name.";
          type = types.nullOr types.str;
        };
        "path" = mkOption {
          description = "Path defines the path that must exist in the requested URL for the browser to send the Cookie header.\nWhen not provided the cookie will be sent on every request to the domain.\nMore info: https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Set-Cookie#pathpath-value";
          type = types.nullOr types.str;
        };
        "sameSite" = mkOption {
          description = "SameSite defines the same site policy.\nMore info: https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Set-Cookie/SameSite";
          type = types.nullOr types.str;
        };
        "secure" = mkOption {
          description = "Secure defines whether the cookie can only be transmitted over an encrypted connection (i.e. HTTPS).";
          type = types.nullOr types.bool;
        };
      };

      config = {
        "domain" = mkOverride 1002 null;
        "httpOnly" = mkOverride 1002 null;
        "maxAge" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "path" = mkOverride 1002 null;
        "sameSite" = mkOverride 1002 null;
        "secure" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.TraefikServiceSpecWeighted" = {

      options = {
        "services" = mkOption {
          description = "Services defines the list of Kubernetes Service and/or TraefikService to load-balance, with weight.";
          type = types.nullOr (
            coerceAttrsOfSubmodulesToListByKey "traefik.io.v1alpha1.TraefikServiceSpecWeightedServices" "name"
              [ ]
          );
          apply = attrsToList;
        };
        "sticky" = mkOption {
          description = "Sticky defines whether sticky sessions are enabled.\nMore info: https://doc.traefik.io/traefik/v3.6/reference/routing-configuration/kubernetes/crd/http/traefikservice/#stickiness-and-load-balancing";
          type = types.nullOr (submoduleOf "traefik.io.v1alpha1.TraefikServiceSpecWeightedSticky");
        };
      };

      config = {
        "services" = mkOverride 1002 null;
        "sticky" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.TraefikServiceSpecWeightedServices" = {

      options = {
        "healthCheck" = mkOption {
          description = "Healthcheck defines health checks for ExternalName services.";
          type = types.nullOr (
            submoduleOf "traefik.io.v1alpha1.TraefikServiceSpecWeightedServicesHealthCheck"
          );
        };
        "kind" = mkOption {
          description = "Kind defines the kind of the Service.";
          type = types.nullOr types.str;
        };
        "name" = mkOption {
          description = "Name defines the name of the referenced Kubernetes Service or TraefikService.\nThe differentiation between the two is specified in the Kind field.";
          type = types.str;
        };
        "namespace" = mkOption {
          description = "Namespace defines the namespace of the referenced Kubernetes Service or TraefikService.";
          type = types.nullOr types.str;
        };
        "nativeLB" = mkOption {
          description = "NativeLB controls, when creating the load-balancer,\nwhether the LB's children are directly the pods IPs or if the only child is the Kubernetes Service clusterIP.\nThe Kubernetes Service itself does load-balance to the pods.\nBy default, NativeLB is false.";
          type = types.nullOr types.bool;
        };
        "nodePortLB" = mkOption {
          description = "NodePortLB controls, when creating the load-balancer,\nwhether the LB's children are directly the nodes internal IPs using the nodePort when the service type is NodePort.\nIt allows services to be reachable when Traefik runs externally from the Kubernetes cluster but within the same network of the nodes.\nBy default, NodePortLB is false.";
          type = types.nullOr types.bool;
        };
        "passHostHeader" = mkOption {
          description = "PassHostHeader defines whether the client Host header is forwarded to the upstream Kubernetes Service.\nBy default, passHostHeader is true.";
          type = types.nullOr types.bool;
        };
        "passiveHealthCheck" = mkOption {
          description = "PassiveHealthCheck defines passive health checks for ExternalName services.";
          type = types.nullOr (
            submoduleOf "traefik.io.v1alpha1.TraefikServiceSpecWeightedServicesPassiveHealthCheck"
          );
        };
        "port" = mkOption {
          description = "Port defines the port of a Kubernetes Service.\nThis can be a reference to a named port.";
          type = types.nullOr (types.either types.int types.str);
        };
        "responseForwarding" = mkOption {
          description = "ResponseForwarding defines how Traefik forwards the response from the upstream Kubernetes Service to the client.";
          type = types.nullOr (
            submoduleOf "traefik.io.v1alpha1.TraefikServiceSpecWeightedServicesResponseForwarding"
          );
        };
        "scheme" = mkOption {
          description = "Scheme defines the scheme to use for the request to the upstream Kubernetes Service.\nIt defaults to https when Kubernetes Service port is 443, http otherwise.";
          type = types.nullOr types.str;
        };
        "serversTransport" = mkOption {
          description = "ServersTransport defines the name of ServersTransport resource to use.\nIt allows to configure the transport between Traefik and your servers.\nCan only be used on a Kubernetes Service.";
          type = types.nullOr types.str;
        };
        "sticky" = mkOption {
          description = "Sticky defines the sticky sessions configuration.\nMore info: https://doc.traefik.io/traefik/v3.6/reference/routing-configuration/http/load-balancing/service/#sticky-sessions";
          type = types.nullOr (submoduleOf "traefik.io.v1alpha1.TraefikServiceSpecWeightedServicesSticky");
        };
        "strategy" = mkOption {
          description = "Strategy defines the load balancing strategy between the servers.\nSupported values are: wrr (Weighed round-robin), p2c (Power of two choices), hrw (Highest Random Weight), and leasttime (Least-Time).\nRoundRobin value is deprecated and supported for backward compatibility.";
          type = types.nullOr types.str;
        };
        "weight" = mkOption {
          description = "Weight defines the weight and should only be specified when Name references a TraefikService object\n(and to be precise, one that embeds a Weighted Round Robin).";
          type = types.nullOr types.int;
        };
      };

      config = {
        "healthCheck" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
        "nativeLB" = mkOverride 1002 null;
        "nodePortLB" = mkOverride 1002 null;
        "passHostHeader" = mkOverride 1002 null;
        "passiveHealthCheck" = mkOverride 1002 null;
        "port" = mkOverride 1002 null;
        "responseForwarding" = mkOverride 1002 null;
        "scheme" = mkOverride 1002 null;
        "serversTransport" = mkOverride 1002 null;
        "sticky" = mkOverride 1002 null;
        "strategy" = mkOverride 1002 null;
        "weight" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.TraefikServiceSpecWeightedServicesHealthCheck" = {

      options = {
        "followRedirects" = mkOption {
          description = "FollowRedirects defines whether redirects should be followed during the health check calls.\nDefault: true";
          type = types.nullOr types.bool;
        };
        "headers" = mkOption {
          description = "Headers defines custom headers to be sent to the health check endpoint.";
          type = types.nullOr (types.attrsOf types.str);
        };
        "hostname" = mkOption {
          description = "Hostname defines the value of hostname in the Host header of the health check request.";
          type = types.nullOr types.str;
        };
        "interval" = mkOption {
          description = "Interval defines the frequency of the health check calls for healthy targets.\nDefault: 30s";
          type = types.nullOr (types.either types.int types.str);
        };
        "method" = mkOption {
          description = "Method defines the healthcheck method.";
          type = types.nullOr types.str;
        };
        "mode" = mkOption {
          description = "Mode defines the health check mode.\nIf defined to grpc, will use the gRPC health check protocol to probe the server.\nDefault: http";
          type = types.nullOr types.str;
        };
        "path" = mkOption {
          description = "Path defines the server URL path for the health check endpoint.";
          type = types.nullOr types.str;
        };
        "port" = mkOption {
          description = "Port defines the server URL port for the health check endpoint.";
          type = types.nullOr types.int;
        };
        "scheme" = mkOption {
          description = "Scheme replaces the server URL scheme for the health check endpoint.";
          type = types.nullOr types.str;
        };
        "status" = mkOption {
          description = "Status defines the expected HTTP status code of the response to the health check request.";
          type = types.nullOr types.int;
        };
        "timeout" = mkOption {
          description = "Timeout defines the maximum duration Traefik will wait for a health check request before considering the server unhealthy.\nDefault: 5s";
          type = types.nullOr (types.either types.int types.str);
        };
        "unhealthyInterval" = mkOption {
          description = "UnhealthyInterval defines the frequency of the health check calls for unhealthy targets.\nWhen UnhealthyInterval is not defined, it defaults to the Interval value.\nDefault: 30s";
          type = types.nullOr (types.either types.int types.str);
        };
      };

      config = {
        "followRedirects" = mkOverride 1002 null;
        "headers" = mkOverride 1002 null;
        "hostname" = mkOverride 1002 null;
        "interval" = mkOverride 1002 null;
        "method" = mkOverride 1002 null;
        "mode" = mkOverride 1002 null;
        "path" = mkOverride 1002 null;
        "port" = mkOverride 1002 null;
        "scheme" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
        "timeout" = mkOverride 1002 null;
        "unhealthyInterval" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.TraefikServiceSpecWeightedServicesPassiveHealthCheck" = {

      options = {
        "failureWindow" = mkOption {
          description = "FailureWindow defines the time window during which the failed attempts must occur for the server to be marked as unhealthy. It also defines for how long the server will be considered unhealthy.";
          type = types.nullOr (types.either types.int types.str);
        };
        "maxFailedAttempts" = mkOption {
          description = "MaxFailedAttempts is the number of consecutive failed attempts allowed within the failure window before marking the server as unhealthy.";
          type = types.nullOr types.int;
        };
      };

      config = {
        "failureWindow" = mkOverride 1002 null;
        "maxFailedAttempts" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.TraefikServiceSpecWeightedServicesResponseForwarding" = {

      options = {
        "flushInterval" = mkOption {
          description = "FlushInterval defines the interval, in milliseconds, in between flushes to the client while copying the response body.\nA negative value means to flush immediately after each write to the client.\nThis configuration is ignored when ReverseProxy recognizes a response as a streaming response;\nfor such responses, writes are flushed to the client immediately.\nDefault: 100ms";
          type = types.nullOr types.str;
        };
      };

      config = {
        "flushInterval" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.TraefikServiceSpecWeightedServicesSticky" = {

      options = {
        "cookie" = mkOption {
          description = "Cookie defines the sticky cookie configuration.";
          type = types.nullOr (
            submoduleOf "traefik.io.v1alpha1.TraefikServiceSpecWeightedServicesStickyCookie"
          );
        };
      };

      config = {
        "cookie" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.TraefikServiceSpecWeightedServicesStickyCookie" = {

      options = {
        "domain" = mkOption {
          description = "Domain defines the host to which the cookie will be sent.\nMore info: https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Set-Cookie#domaindomain-value";
          type = types.nullOr types.str;
        };
        "httpOnly" = mkOption {
          description = "HTTPOnly defines whether the cookie can be accessed by client-side APIs, such as JavaScript.";
          type = types.nullOr types.bool;
        };
        "maxAge" = mkOption {
          description = "MaxAge defines the number of seconds until the cookie expires.\nWhen set to a negative number, the cookie expires immediately.\nWhen set to zero, the cookie never expires.";
          type = types.nullOr types.int;
        };
        "name" = mkOption {
          description = "Name defines the Cookie name.";
          type = types.nullOr types.str;
        };
        "path" = mkOption {
          description = "Path defines the path that must exist in the requested URL for the browser to send the Cookie header.\nWhen not provided the cookie will be sent on every request to the domain.\nMore info: https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Set-Cookie#pathpath-value";
          type = types.nullOr types.str;
        };
        "sameSite" = mkOption {
          description = "SameSite defines the same site policy.\nMore info: https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Set-Cookie/SameSite";
          type = types.nullOr types.str;
        };
        "secure" = mkOption {
          description = "Secure defines whether the cookie can only be transmitted over an encrypted connection (i.e. HTTPS).";
          type = types.nullOr types.bool;
        };
      };

      config = {
        "domain" = mkOverride 1002 null;
        "httpOnly" = mkOverride 1002 null;
        "maxAge" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "path" = mkOverride 1002 null;
        "sameSite" = mkOverride 1002 null;
        "secure" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.TraefikServiceSpecWeightedSticky" = {

      options = {
        "cookie" = mkOption {
          description = "Cookie defines the sticky cookie configuration.";
          type = types.nullOr (submoduleOf "traefik.io.v1alpha1.TraefikServiceSpecWeightedStickyCookie");
        };
      };

      config = {
        "cookie" = mkOverride 1002 null;
      };

    };
    "traefik.io.v1alpha1.TraefikServiceSpecWeightedStickyCookie" = {

      options = {
        "domain" = mkOption {
          description = "Domain defines the host to which the cookie will be sent.\nMore info: https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Set-Cookie#domaindomain-value";
          type = types.nullOr types.str;
        };
        "httpOnly" = mkOption {
          description = "HTTPOnly defines whether the cookie can be accessed by client-side APIs, such as JavaScript.";
          type = types.nullOr types.bool;
        };
        "maxAge" = mkOption {
          description = "MaxAge defines the number of seconds until the cookie expires.\nWhen set to a negative number, the cookie expires immediately.\nWhen set to zero, the cookie never expires.";
          type = types.nullOr types.int;
        };
        "name" = mkOption {
          description = "Name defines the Cookie name.";
          type = types.nullOr types.str;
        };
        "path" = mkOption {
          description = "Path defines the path that must exist in the requested URL for the browser to send the Cookie header.\nWhen not provided the cookie will be sent on every request to the domain.\nMore info: https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Set-Cookie#pathpath-value";
          type = types.nullOr types.str;
        };
        "sameSite" = mkOption {
          description = "SameSite defines the same site policy.\nMore info: https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Set-Cookie/SameSite";
          type = types.nullOr types.str;
        };
        "secure" = mkOption {
          description = "Secure defines whether the cookie can only be transmitted over an encrypted connection (i.e. HTTPS).";
          type = types.nullOr types.bool;
        };
      };

      config = {
        "domain" = mkOverride 1002 null;
        "httpOnly" = mkOverride 1002 null;
        "maxAge" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "path" = mkOverride 1002 null;
        "sameSite" = mkOverride 1002 null;
        "secure" = mkOverride 1002 null;
      };

    };

  };
in
{
  # all resource versions
  options = {
    resources = {
      "gateway.networking.k8s.io"."v1"."BackendTLSPolicy" = mkOption {
        description = "BackendTLSPolicy provides a way to configure how a Gateway\nconnects to a Backend via TLS.";
        type = types.attrsOf (
          submoduleForDefinition "gateway.networking.k8s.io.v1.BackendTLSPolicy" "backendtlspolicies"
            "BackendTLSPolicy"
            "gateway.networking.k8s.io"
            "v1"
        );
        default = { };
      };
      "gateway.networking.k8s.io"."v1"."GRPCRoute" = mkOption {
        description = "GRPCRoute provides a way to route gRPC requests. This includes the capability\nto match requests by hostname, gRPC service, gRPC method, or HTTP/2 header.\nFilters can be used to specify additional processing steps. Backends specify\nwhere matching requests will be routed.\n\nGRPCRoute falls under extended support within the Gateway API. Within the\nfollowing specification, the word \"MUST\" indicates that an implementation\nsupporting GRPCRoute must conform to the indicated requirement, but an\nimplementation not supporting this route type need not follow the requirement\nunless explicitly indicated.\n\nImplementations supporting `GRPCRoute` with the `HTTPS` `ProtocolType` MUST\naccept HTTP/2 connections without an initial upgrade from HTTP/1.1, i.e. via\nALPN. If the implementation does not support this, then it MUST set the\n\"Accepted\" condition to \"False\" for the affected listener with a reason of\n\"UnsupportedProtocol\".  Implementations MAY also accept HTTP/2 connections\nwith an upgrade from HTTP/1.\n\nImplementations supporting `GRPCRoute` with the `HTTP` `ProtocolType` MUST\nsupport HTTP/2 over cleartext TCP (h2c,\nhttps://www.rfc-editor.org/rfc/rfc7540#section-3.1) without an initial\nupgrade from HTTP/1.1, i.e. with prior knowledge\n(https://www.rfc-editor.org/rfc/rfc7540#section-3.4). If the implementation\ndoes not support this, then it MUST set the \"Accepted\" condition to \"False\"\nfor the affected listener with a reason of \"UnsupportedProtocol\".\nImplementations MAY also accept HTTP/2 connections with an upgrade from\nHTTP/1, i.e. without prior knowledge.";
        type = types.attrsOf (
          submoduleForDefinition "gateway.networking.k8s.io.v1.GRPCRoute" "grpcroutes" "GRPCRoute"
            "gateway.networking.k8s.io"
            "v1"
        );
        default = { };
      };
      "gateway.networking.k8s.io"."v1"."Gateway" = mkOption {
        description = "Gateway represents an instance of a service-traffic handling infrastructure\nby binding Listeners to a set of IP addresses.";
        type = types.attrsOf (
          submoduleForDefinition "gateway.networking.k8s.io.v1.Gateway" "gateways" "Gateway"
            "gateway.networking.k8s.io"
            "v1"
        );
        default = { };
      };
      "gateway.networking.k8s.io"."v1"."GatewayClass" = mkOption {
        description = "GatewayClass describes a class of Gateways available to the user for creating\nGateway resources.\n\nIt is recommended that this resource be used as a template for Gateways. This\nmeans that a Gateway is based on the state of the GatewayClass at the time it\nwas created and changes to the GatewayClass or associated parameters are not\npropagated down to existing Gateways. This recommendation is intended to\nlimit the blast radius of changes to GatewayClass or associated parameters.\nIf implementations choose to propagate GatewayClass changes to existing\nGateways, that MUST be clearly documented by the implementation.\n\nWhenever one or more Gateways are using a GatewayClass, implementations SHOULD\nadd the `gateway-exists-finalizer.gateway.networking.k8s.io` finalizer on the\nassociated GatewayClass. This ensures that a GatewayClass associated with a\nGateway is not deleted while in use.\n\nGatewayClass is a Cluster level resource.";
        type = types.attrsOf (
          submoduleForDefinition "gateway.networking.k8s.io.v1.GatewayClass" "gatewayclasses" "GatewayClass"
            "gateway.networking.k8s.io"
            "v1"
        );
        default = { };
      };
      "gateway.networking.k8s.io"."v1"."HTTPRoute" = mkOption {
        description = "HTTPRoute provides a way to route HTTP requests. This includes the capability\nto match requests by hostname, path, header, or query param. Filters can be\nused to specify additional processing steps. Backends specify where matching\nrequests should be routed.";
        type = types.attrsOf (
          submoduleForDefinition "gateway.networking.k8s.io.v1.HTTPRoute" "httproutes" "HTTPRoute"
            "gateway.networking.k8s.io"
            "v1"
        );
        default = { };
      };
      "gateway.networking.k8s.io"."v1beta1"."Gateway" = mkOption {
        description = "Gateway represents an instance of a service-traffic handling infrastructure\nby binding Listeners to a set of IP addresses.";
        type = types.attrsOf (
          submoduleForDefinition "gateway.networking.k8s.io.v1beta1.Gateway" "gateways" "Gateway"
            "gateway.networking.k8s.io"
            "v1beta1"
        );
        default = { };
      };
      "gateway.networking.k8s.io"."v1beta1"."GatewayClass" = mkOption {
        description = "GatewayClass describes a class of Gateways available to the user for creating\nGateway resources.\n\nIt is recommended that this resource be used as a template for Gateways. This\nmeans that a Gateway is based on the state of the GatewayClass at the time it\nwas created and changes to the GatewayClass or associated parameters are not\npropagated down to existing Gateways. This recommendation is intended to\nlimit the blast radius of changes to GatewayClass or associated parameters.\nIf implementations choose to propagate GatewayClass changes to existing\nGateways, that MUST be clearly documented by the implementation.\n\nWhenever one or more Gateways are using a GatewayClass, implementations SHOULD\nadd the `gateway-exists-finalizer.gateway.networking.k8s.io` finalizer on the\nassociated GatewayClass. This ensures that a GatewayClass associated with a\nGateway is not deleted while in use.\n\nGatewayClass is a Cluster level resource.";
        type = types.attrsOf (
          submoduleForDefinition "gateway.networking.k8s.io.v1beta1.GatewayClass" "gatewayclasses"
            "GatewayClass"
            "gateway.networking.k8s.io"
            "v1beta1"
        );
        default = { };
      };
      "gateway.networking.k8s.io"."v1beta1"."HTTPRoute" = mkOption {
        description = "HTTPRoute provides a way to route HTTP requests. This includes the capability\nto match requests by hostname, path, header, or query param. Filters can be\nused to specify additional processing steps. Backends specify where matching\nrequests should be routed.";
        type = types.attrsOf (
          submoduleForDefinition "gateway.networking.k8s.io.v1beta1.HTTPRoute" "httproutes" "HTTPRoute"
            "gateway.networking.k8s.io"
            "v1beta1"
        );
        default = { };
      };
      "gateway.networking.k8s.io"."v1beta1"."ReferenceGrant" = mkOption {
        description = "ReferenceGrant identifies kinds of resources in other namespaces that are\ntrusted to reference the specified kinds of resources in the same namespace\nas the policy.\n\nEach ReferenceGrant can be used to represent a unique trust relationship.\nAdditional Reference Grants can be used to add to the set of trusted\nsources of inbound references for the namespace they are defined within.\n\nAll cross-namespace references in Gateway API (with the exception of cross-namespace\nGateway-route attachment) require a ReferenceGrant.\n\nReferenceGrant is a form of runtime verification allowing users to assert\nwhich cross-namespace object references are permitted. Implementations that\nsupport ReferenceGrant MUST NOT permit cross-namespace references which have\nno grant, and MUST respond to the removal of a grant by revoking the access\nthat the grant allowed.";
        type = types.attrsOf (
          submoduleForDefinition "gateway.networking.k8s.io.v1beta1.ReferenceGrant" "referencegrants"
            "ReferenceGrant"
            "gateway.networking.k8s.io"
            "v1beta1"
        );
        default = { };
      };
      "hub.traefik.io"."v1alpha1"."AIService" = mkOption {
        description = "AIService is a Kubernetes-like Service to interact with a text-based LLM provider. It defines the parameters and credentials required to interact with various LLM providers.";
        type = types.attrsOf (
          submoduleForDefinition "hub.traefik.io.v1alpha1.AIService" "aiservices" "AIService" "hub.traefik.io"
            "v1alpha1"
        );
        default = { };
      };
      "hub.traefik.io"."v1alpha1"."API" = mkOption {
        description = "API defines an HTTP interface that is exposed to external clients. It specifies the supported versions\nand provides instructions for accessing its documentation. Once instantiated, an API object is associated\nwith an Ingress, IngressRoute, or HTTPRoute resource, enabling the exposure of the described API to the outside world.";
        type = types.attrsOf (
          submoduleForDefinition "hub.traefik.io.v1alpha1.API" "apis" "API" "hub.traefik.io" "v1alpha1"
        );
        default = { };
      };
      "hub.traefik.io"."v1alpha1"."APIAuth" = mkOption {
        description = "APIAuth defines the authentication configuration for APIs.";
        type = types.attrsOf (
          submoduleForDefinition "hub.traefik.io.v1alpha1.APIAuth" "apiauths" "APIAuth" "hub.traefik.io"
            "v1alpha1"
        );
        default = { };
      };
      "hub.traefik.io"."v1alpha1"."APIBundle" = mkOption {
        description = "APIBundle defines a set of APIs.";
        type = types.attrsOf (
          submoduleForDefinition "hub.traefik.io.v1alpha1.APIBundle" "apibundles" "APIBundle" "hub.traefik.io"
            "v1alpha1"
        );
        default = { };
      };
      "hub.traefik.io"."v1alpha1"."APICatalogItem" = mkOption {
        description = "APICatalogItem defines APIs that will be part of the API catalog on the portal.";
        type = types.attrsOf (
          submoduleForDefinition "hub.traefik.io.v1alpha1.APICatalogItem" "apicatalogitems" "APICatalogItem"
            "hub.traefik.io"
            "v1alpha1"
        );
        default = { };
      };
      "hub.traefik.io"."v1alpha1"."APIPlan" = mkOption {
        description = "APIPlan defines API Plan policy.";
        type = types.attrsOf (
          submoduleForDefinition "hub.traefik.io.v1alpha1.APIPlan" "apiplans" "APIPlan" "hub.traefik.io"
            "v1alpha1"
        );
        default = { };
      };
      "hub.traefik.io"."v1alpha1"."APIPortal" = mkOption {
        description = "APIPortal defines a developer portal for accessing the documentation of APIs.";
        type = types.attrsOf (
          submoduleForDefinition "hub.traefik.io.v1alpha1.APIPortal" "apiportals" "APIPortal" "hub.traefik.io"
            "v1alpha1"
        );
        default = { };
      };
      "hub.traefik.io"."v1alpha1"."APIPortalAuth" = mkOption {
        description = "APIPortalAuth defines the authentication configuration for an APIPortal.";
        type = types.attrsOf (
          submoduleForDefinition "hub.traefik.io.v1alpha1.APIPortalAuth" "apiportalauths" "APIPortalAuth"
            "hub.traefik.io"
            "v1alpha1"
        );
        default = { };
      };
      "hub.traefik.io"."v1alpha1"."APIRateLimit" = mkOption {
        description = "APIRateLimit defines how group of consumers are rate limited on a set of APIs.";
        type = types.attrsOf (
          submoduleForDefinition "hub.traefik.io.v1alpha1.APIRateLimit" "apiratelimits" "APIRateLimit"
            "hub.traefik.io"
            "v1alpha1"
        );
        default = { };
      };
      "hub.traefik.io"."v1alpha1"."APIVersion" = mkOption {
        description = "APIVersion defines a version of an API.";
        type = types.attrsOf (
          submoduleForDefinition "hub.traefik.io.v1alpha1.APIVersion" "apiversions" "APIVersion"
            "hub.traefik.io"
            "v1alpha1"
        );
        default = { };
      };
      "hub.traefik.io"."v1alpha1"."AccessControlPolicy" = mkOption {
        description = "AccessControlPolicy defines an access control policy.";
        type = types.attrsOf (
          submoduleForDefinition "hub.traefik.io.v1alpha1.AccessControlPolicy" "accesscontrolpolicies"
            "AccessControlPolicy"
            "hub.traefik.io"
            "v1alpha1"
        );
        default = { };
      };
      "hub.traefik.io"."v1alpha1"."ManagedApplication" = mkOption {
        description = "ManagedApplication represents a managed application.";
        type = types.attrsOf (
          submoduleForDefinition "hub.traefik.io.v1alpha1.ManagedApplication" "managedapplications"
            "ManagedApplication"
            "hub.traefik.io"
            "v1alpha1"
        );
        default = { };
      };
      "hub.traefik.io"."v1alpha1"."ManagedSubscription" = mkOption {
        description = "ManagedSubscription defines a Subscription managed by the API manager as the result of a pre-negotiation with its\nAPI consumers. This subscription grant consuming access to a set of APIs to a set of Applications.";
        type = types.attrsOf (
          submoduleForDefinition "hub.traefik.io.v1alpha1.ManagedSubscription" "managedsubscriptions"
            "ManagedSubscription"
            "hub.traefik.io"
            "v1alpha1"
        );
        default = { };
      };
      "traefik.io"."v1alpha1"."IngressRoute" = mkOption {
        description = "IngressRoute is the CRD implementation of a Traefik HTTP Router.";
        type = types.attrsOf (
          submoduleForDefinition "traefik.io.v1alpha1.IngressRoute" "ingressroutes" "IngressRoute"
            "traefik.io"
            "v1alpha1"
        );
        default = { };
      };
      "traefik.io"."v1alpha1"."IngressRouteTCP" = mkOption {
        description = "IngressRouteTCP is the CRD implementation of a Traefik TCP Router.";
        type = types.attrsOf (
          submoduleForDefinition "traefik.io.v1alpha1.IngressRouteTCP" "ingressroutetcps" "IngressRouteTCP"
            "traefik.io"
            "v1alpha1"
        );
        default = { };
      };
      "traefik.io"."v1alpha1"."IngressRouteUDP" = mkOption {
        description = "IngressRouteUDP is a CRD implementation of a Traefik UDP Router.";
        type = types.attrsOf (
          submoduleForDefinition "traefik.io.v1alpha1.IngressRouteUDP" "ingressrouteudps" "IngressRouteUDP"
            "traefik.io"
            "v1alpha1"
        );
        default = { };
      };
      "traefik.io"."v1alpha1"."Middleware" = mkOption {
        description = "Middleware is the CRD implementation of a Traefik Middleware.\nMore info: https://doc.traefik.io/traefik/v3.6/reference/routing-configuration/http/middlewares/overview/";
        type = types.attrsOf (
          submoduleForDefinition "traefik.io.v1alpha1.Middleware" "middlewares" "Middleware" "traefik.io"
            "v1alpha1"
        );
        default = { };
      };
      "traefik.io"."v1alpha1"."MiddlewareTCP" = mkOption {
        description = "MiddlewareTCP is the CRD implementation of a Traefik TCP middleware.\nMore info: https://doc.traefik.io/traefik/v3.6/reference/routing-configuration/tcp/middlewares/overview/";
        type = types.attrsOf (
          submoduleForDefinition "traefik.io.v1alpha1.MiddlewareTCP" "middlewaretcps" "MiddlewareTCP"
            "traefik.io"
            "v1alpha1"
        );
        default = { };
      };
      "traefik.io"."v1alpha1"."ServersTransport" = mkOption {
        description = "ServersTransport is the CRD implementation of a ServersTransport.\nIf no serversTransport is specified, the default@internal will be used.\nThe default@internal serversTransport is created from the static configuration.\nMore info: https://doc.traefik.io/traefik/v3.6/reference/routing-configuration/http/load-balancing/serverstransport/";
        type = types.attrsOf (
          submoduleForDefinition "traefik.io.v1alpha1.ServersTransport" "serverstransports" "ServersTransport"
            "traefik.io"
            "v1alpha1"
        );
        default = { };
      };
      "traefik.io"."v1alpha1"."ServersTransportTCP" = mkOption {
        description = "ServersTransportTCP is the CRD implementation of a TCPServersTransport.\nIf no tcpServersTransport is specified, a default one named default@internal will be used.\nThe default@internal tcpServersTransport can be configured in the static configuration.\nMore info: https://doc.traefik.io/traefik/v3.6/reference/routing-configuration/tcp/serverstransport/";
        type = types.attrsOf (
          submoduleForDefinition "traefik.io.v1alpha1.ServersTransportTCP" "serverstransporttcps"
            "ServersTransportTCP"
            "traefik.io"
            "v1alpha1"
        );
        default = { };
      };
      "traefik.io"."v1alpha1"."TLSOption" = mkOption {
        description = "TLSOption is the CRD implementation of a Traefik TLS Option, allowing to configure some parameters of the TLS connection.\nMore info: https://doc.traefik.io/traefik/v3.6/reference/routing-configuration/http/tls/tls-certificates/#certificates-stores#tls-options";
        type = types.attrsOf (
          submoduleForDefinition "traefik.io.v1alpha1.TLSOption" "tlsoptions" "TLSOption" "traefik.io"
            "v1alpha1"
        );
        default = { };
      };
      "traefik.io"."v1alpha1"."TLSStore" = mkOption {
        description = "TLSStore is the CRD implementation of a Traefik TLS Store.\nFor the time being, only the TLSStore named default is supported.\nThis means that you cannot have two stores that are named default in different Kubernetes namespaces.\nMore info: https://doc.traefik.io/traefik/v3.6/reference/routing-configuration/http/tls/tls-certificates/#certificates-stores#certificates-stores";
        type = types.attrsOf (
          submoduleForDefinition "traefik.io.v1alpha1.TLSStore" "tlsstores" "TLSStore" "traefik.io" "v1alpha1"
        );
        default = { };
      };
      "traefik.io"."v1alpha1"."TraefikService" = mkOption {
        description = "TraefikService is the CRD implementation of a Traefik Service.\nTraefikService object allows to:\n- Apply weight to Services on load-balancing\n- Mirror traffic on services\nMore info: https://doc.traefik.io/traefik/v3.6/reference/routing-configuration/kubernetes/crd/http/traefikservice/";
        type = types.attrsOf (
          submoduleForDefinition "traefik.io.v1alpha1.TraefikService" "traefikservices" "TraefikService"
            "traefik.io"
            "v1alpha1"
        );
        default = { };
      };

    }
    // {
      "aiServices" = mkOption {
        description = "AIService is a Kubernetes-like Service to interact with a text-based LLM provider. It defines the parameters and credentials required to interact with various LLM providers.";
        type = types.attrsOf (
          submoduleForDefinition "hub.traefik.io.v1alpha1.AIService" "aiservices" "AIService" "hub.traefik.io"
            "v1alpha1"
        );
        default = { };
      };
      "apis" = mkOption {
        description = "API defines an HTTP interface that is exposed to external clients. It specifies the supported versions\nand provides instructions for accessing its documentation. Once instantiated, an API object is associated\nwith an Ingress, IngressRoute, or HTTPRoute resource, enabling the exposure of the described API to the outside world.";
        type = types.attrsOf (
          submoduleForDefinition "hub.traefik.io.v1alpha1.API" "apis" "API" "hub.traefik.io" "v1alpha1"
        );
        default = { };
      };
      "apiAuths" = mkOption {
        description = "APIAuth defines the authentication configuration for APIs.";
        type = types.attrsOf (
          submoduleForDefinition "hub.traefik.io.v1alpha1.APIAuth" "apiauths" "APIAuth" "hub.traefik.io"
            "v1alpha1"
        );
        default = { };
      };
      "apiBundles" = mkOption {
        description = "APIBundle defines a set of APIs.";
        type = types.attrsOf (
          submoduleForDefinition "hub.traefik.io.v1alpha1.APIBundle" "apibundles" "APIBundle" "hub.traefik.io"
            "v1alpha1"
        );
        default = { };
      };
      "apiCatalogItems" = mkOption {
        description = "APICatalogItem defines APIs that will be part of the API catalog on the portal.";
        type = types.attrsOf (
          submoduleForDefinition "hub.traefik.io.v1alpha1.APICatalogItem" "apicatalogitems" "APICatalogItem"
            "hub.traefik.io"
            "v1alpha1"
        );
        default = { };
      };
      "apiPlans" = mkOption {
        description = "APIPlan defines API Plan policy.";
        type = types.attrsOf (
          submoduleForDefinition "hub.traefik.io.v1alpha1.APIPlan" "apiplans" "APIPlan" "hub.traefik.io"
            "v1alpha1"
        );
        default = { };
      };
      "apiPortals" = mkOption {
        description = "APIPortal defines a developer portal for accessing the documentation of APIs.";
        type = types.attrsOf (
          submoduleForDefinition "hub.traefik.io.v1alpha1.APIPortal" "apiportals" "APIPortal" "hub.traefik.io"
            "v1alpha1"
        );
        default = { };
      };
      "apiPortalAuths" = mkOption {
        description = "APIPortalAuth defines the authentication configuration for an APIPortal.";
        type = types.attrsOf (
          submoduleForDefinition "hub.traefik.io.v1alpha1.APIPortalAuth" "apiportalauths" "APIPortalAuth"
            "hub.traefik.io"
            "v1alpha1"
        );
        default = { };
      };
      "apiRateLimits" = mkOption {
        description = "APIRateLimit defines how group of consumers are rate limited on a set of APIs.";
        type = types.attrsOf (
          submoduleForDefinition "hub.traefik.io.v1alpha1.APIRateLimit" "apiratelimits" "APIRateLimit"
            "hub.traefik.io"
            "v1alpha1"
        );
        default = { };
      };
      "apiVersions" = mkOption {
        description = "APIVersion defines a version of an API.";
        type = types.attrsOf (
          submoduleForDefinition "hub.traefik.io.v1alpha1.APIVersion" "apiversions" "APIVersion"
            "hub.traefik.io"
            "v1alpha1"
        );
        default = { };
      };
      "accessControlPolicies" = mkOption {
        description = "AccessControlPolicy defines an access control policy.";
        type = types.attrsOf (
          submoduleForDefinition "hub.traefik.io.v1alpha1.AccessControlPolicy" "accesscontrolpolicies"
            "AccessControlPolicy"
            "hub.traefik.io"
            "v1alpha1"
        );
        default = { };
      };
      "backendTLSPolicies" = mkOption {
        description = "BackendTLSPolicy provides a way to configure how a Gateway\nconnects to a Backend via TLS.";
        type = types.attrsOf (
          submoduleForDefinition "gateway.networking.k8s.io.v1.BackendTLSPolicy" "backendtlspolicies"
            "BackendTLSPolicy"
            "gateway.networking.k8s.io"
            "v1"
        );
        default = { };
      };
      "grpcRoutes" = mkOption {
        description = "GRPCRoute provides a way to route gRPC requests. This includes the capability\nto match requests by hostname, gRPC service, gRPC method, or HTTP/2 header.\nFilters can be used to specify additional processing steps. Backends specify\nwhere matching requests will be routed.\n\nGRPCRoute falls under extended support within the Gateway API. Within the\nfollowing specification, the word \"MUST\" indicates that an implementation\nsupporting GRPCRoute must conform to the indicated requirement, but an\nimplementation not supporting this route type need not follow the requirement\nunless explicitly indicated.\n\nImplementations supporting `GRPCRoute` with the `HTTPS` `ProtocolType` MUST\naccept HTTP/2 connections without an initial upgrade from HTTP/1.1, i.e. via\nALPN. If the implementation does not support this, then it MUST set the\n\"Accepted\" condition to \"False\" for the affected listener with a reason of\n\"UnsupportedProtocol\".  Implementations MAY also accept HTTP/2 connections\nwith an upgrade from HTTP/1.\n\nImplementations supporting `GRPCRoute` with the `HTTP` `ProtocolType` MUST\nsupport HTTP/2 over cleartext TCP (h2c,\nhttps://www.rfc-editor.org/rfc/rfc7540#section-3.1) without an initial\nupgrade from HTTP/1.1, i.e. with prior knowledge\n(https://www.rfc-editor.org/rfc/rfc7540#section-3.4). If the implementation\ndoes not support this, then it MUST set the \"Accepted\" condition to \"False\"\nfor the affected listener with a reason of \"UnsupportedProtocol\".\nImplementations MAY also accept HTTP/2 connections with an upgrade from\nHTTP/1, i.e. without prior knowledge.";
        type = types.attrsOf (
          submoduleForDefinition "gateway.networking.k8s.io.v1.GRPCRoute" "grpcroutes" "GRPCRoute"
            "gateway.networking.k8s.io"
            "v1"
        );
        default = { };
      };
      "gateways" = mkOption {
        description = "Gateway represents an instance of a service-traffic handling infrastructure\nby binding Listeners to a set of IP addresses.";
        type = types.attrsOf (
          submoduleForDefinition "gateway.networking.k8s.io.v1.Gateway" "gateways" "Gateway"
            "gateway.networking.k8s.io"
            "v1"
        );
        default = { };
      };
      "gatewayClasses" = mkOption {
        description = "GatewayClass describes a class of Gateways available to the user for creating\nGateway resources.\n\nIt is recommended that this resource be used as a template for Gateways. This\nmeans that a Gateway is based on the state of the GatewayClass at the time it\nwas created and changes to the GatewayClass or associated parameters are not\npropagated down to existing Gateways. This recommendation is intended to\nlimit the blast radius of changes to GatewayClass or associated parameters.\nIf implementations choose to propagate GatewayClass changes to existing\nGateways, that MUST be clearly documented by the implementation.\n\nWhenever one or more Gateways are using a GatewayClass, implementations SHOULD\nadd the `gateway-exists-finalizer.gateway.networking.k8s.io` finalizer on the\nassociated GatewayClass. This ensures that a GatewayClass associated with a\nGateway is not deleted while in use.\n\nGatewayClass is a Cluster level resource.";
        type = types.attrsOf (
          submoduleForDefinition "gateway.networking.k8s.io.v1.GatewayClass" "gatewayclasses" "GatewayClass"
            "gateway.networking.k8s.io"
            "v1"
        );
        default = { };
      };
      "httpRoutes" = mkOption {
        description = "HTTPRoute provides a way to route HTTP requests. This includes the capability\nto match requests by hostname, path, header, or query param. Filters can be\nused to specify additional processing steps. Backends specify where matching\nrequests should be routed.";
        type = types.attrsOf (
          submoduleForDefinition "gateway.networking.k8s.io.v1.HTTPRoute" "httproutes" "HTTPRoute"
            "gateway.networking.k8s.io"
            "v1"
        );
        default = { };
      };
      "ingressRoutes" = mkOption {
        description = "IngressRoute is the CRD implementation of a Traefik HTTP Router.";
        type = types.attrsOf (
          submoduleForDefinition "traefik.io.v1alpha1.IngressRoute" "ingressroutes" "IngressRoute"
            "traefik.io"
            "v1alpha1"
        );
        default = { };
      };
      "ingressRouteTCPs" = mkOption {
        description = "IngressRouteTCP is the CRD implementation of a Traefik TCP Router.";
        type = types.attrsOf (
          submoduleForDefinition "traefik.io.v1alpha1.IngressRouteTCP" "ingressroutetcps" "IngressRouteTCP"
            "traefik.io"
            "v1alpha1"
        );
        default = { };
      };
      "ingressRouteUDPs" = mkOption {
        description = "IngressRouteUDP is a CRD implementation of a Traefik UDP Router.";
        type = types.attrsOf (
          submoduleForDefinition "traefik.io.v1alpha1.IngressRouteUDP" "ingressrouteudps" "IngressRouteUDP"
            "traefik.io"
            "v1alpha1"
        );
        default = { };
      };
      "managedApplications" = mkOption {
        description = "ManagedApplication represents a managed application.";
        type = types.attrsOf (
          submoduleForDefinition "hub.traefik.io.v1alpha1.ManagedApplication" "managedapplications"
            "ManagedApplication"
            "hub.traefik.io"
            "v1alpha1"
        );
        default = { };
      };
      "managedSubscriptions" = mkOption {
        description = "ManagedSubscription defines a Subscription managed by the API manager as the result of a pre-negotiation with its\nAPI consumers. This subscription grant consuming access to a set of APIs to a set of Applications.";
        type = types.attrsOf (
          submoduleForDefinition "hub.traefik.io.v1alpha1.ManagedSubscription" "managedsubscriptions"
            "ManagedSubscription"
            "hub.traefik.io"
            "v1alpha1"
        );
        default = { };
      };
      "middlewares" = mkOption {
        description = "Middleware is the CRD implementation of a Traefik Middleware.\nMore info: https://doc.traefik.io/traefik/v3.6/reference/routing-configuration/http/middlewares/overview/";
        type = types.attrsOf (
          submoduleForDefinition "traefik.io.v1alpha1.Middleware" "middlewares" "Middleware" "traefik.io"
            "v1alpha1"
        );
        default = { };
      };
      "middlewareTCPs" = mkOption {
        description = "MiddlewareTCP is the CRD implementation of a Traefik TCP middleware.\nMore info: https://doc.traefik.io/traefik/v3.6/reference/routing-configuration/tcp/middlewares/overview/";
        type = types.attrsOf (
          submoduleForDefinition "traefik.io.v1alpha1.MiddlewareTCP" "middlewaretcps" "MiddlewareTCP"
            "traefik.io"
            "v1alpha1"
        );
        default = { };
      };
      "referenceGrants" = mkOption {
        description = "ReferenceGrant identifies kinds of resources in other namespaces that are\ntrusted to reference the specified kinds of resources in the same namespace\nas the policy.\n\nEach ReferenceGrant can be used to represent a unique trust relationship.\nAdditional Reference Grants can be used to add to the set of trusted\nsources of inbound references for the namespace they are defined within.\n\nAll cross-namespace references in Gateway API (with the exception of cross-namespace\nGateway-route attachment) require a ReferenceGrant.\n\nReferenceGrant is a form of runtime verification allowing users to assert\nwhich cross-namespace object references are permitted. Implementations that\nsupport ReferenceGrant MUST NOT permit cross-namespace references which have\nno grant, and MUST respond to the removal of a grant by revoking the access\nthat the grant allowed.";
        type = types.attrsOf (
          submoduleForDefinition "gateway.networking.k8s.io.v1beta1.ReferenceGrant" "referencegrants"
            "ReferenceGrant"
            "gateway.networking.k8s.io"
            "v1beta1"
        );
        default = { };
      };
      "serversTransports" = mkOption {
        description = "ServersTransport is the CRD implementation of a ServersTransport.\nIf no serversTransport is specified, the default@internal will be used.\nThe default@internal serversTransport is created from the static configuration.\nMore info: https://doc.traefik.io/traefik/v3.6/reference/routing-configuration/http/load-balancing/serverstransport/";
        type = types.attrsOf (
          submoduleForDefinition "traefik.io.v1alpha1.ServersTransport" "serverstransports" "ServersTransport"
            "traefik.io"
            "v1alpha1"
        );
        default = { };
      };
      "serversTransportTCPs" = mkOption {
        description = "ServersTransportTCP is the CRD implementation of a TCPServersTransport.\nIf no tcpServersTransport is specified, a default one named default@internal will be used.\nThe default@internal tcpServersTransport can be configured in the static configuration.\nMore info: https://doc.traefik.io/traefik/v3.6/reference/routing-configuration/tcp/serverstransport/";
        type = types.attrsOf (
          submoduleForDefinition "traefik.io.v1alpha1.ServersTransportTCP" "serverstransporttcps"
            "ServersTransportTCP"
            "traefik.io"
            "v1alpha1"
        );
        default = { };
      };
      "tlsOptions" = mkOption {
        description = "TLSOption is the CRD implementation of a Traefik TLS Option, allowing to configure some parameters of the TLS connection.\nMore info: https://doc.traefik.io/traefik/v3.6/reference/routing-configuration/http/tls/tls-certificates/#certificates-stores#tls-options";
        type = types.attrsOf (
          submoduleForDefinition "traefik.io.v1alpha1.TLSOption" "tlsoptions" "TLSOption" "traefik.io"
            "v1alpha1"
        );
        default = { };
      };
      "tlsStores" = mkOption {
        description = "TLSStore is the CRD implementation of a Traefik TLS Store.\nFor the time being, only the TLSStore named default is supported.\nThis means that you cannot have two stores that are named default in different Kubernetes namespaces.\nMore info: https://doc.traefik.io/traefik/v3.6/reference/routing-configuration/http/tls/tls-certificates/#certificates-stores#certificates-stores";
        type = types.attrsOf (
          submoduleForDefinition "traefik.io.v1alpha1.TLSStore" "tlsstores" "TLSStore" "traefik.io" "v1alpha1"
        );
        default = { };
      };
      "traefikServices" = mkOption {
        description = "TraefikService is the CRD implementation of a Traefik Service.\nTraefikService object allows to:\n- Apply weight to Services on load-balancing\n- Mirror traffic on services\nMore info: https://doc.traefik.io/traefik/v3.6/reference/routing-configuration/kubernetes/crd/http/traefikservice/";
        type = types.attrsOf (
          submoduleForDefinition "traefik.io.v1alpha1.TraefikService" "traefikservices" "TraefikService"
            "traefik.io"
            "v1alpha1"
        );
        default = { };
      };

    };
  };

  config = {
    # expose resource definitions
    inherit definitions;

    # register resource types
    types = [
      {
        name = "backendtlspolicies";
        group = "gateway.networking.k8s.io";
        version = "v1";
        kind = "BackendTLSPolicy";
        attrName = "backendTLSPolicies";
      }
      {
        name = "grpcroutes";
        group = "gateway.networking.k8s.io";
        version = "v1";
        kind = "GRPCRoute";
        attrName = "grpcRoutes";
      }
      {
        name = "gateways";
        group = "gateway.networking.k8s.io";
        version = "v1";
        kind = "Gateway";
        attrName = "gateways";
      }
      {
        name = "gatewayclasses";
        group = "gateway.networking.k8s.io";
        version = "v1";
        kind = "GatewayClass";
        attrName = "gatewayClasses";
      }
      {
        name = "httproutes";
        group = "gateway.networking.k8s.io";
        version = "v1";
        kind = "HTTPRoute";
        attrName = "httpRoutes";
      }
      {
        name = "gateways";
        group = "gateway.networking.k8s.io";
        version = "v1beta1";
        kind = "Gateway";
        attrName = "gateways";
      }
      {
        name = "gatewayclasses";
        group = "gateway.networking.k8s.io";
        version = "v1beta1";
        kind = "GatewayClass";
        attrName = "gatewayClasses";
      }
      {
        name = "httproutes";
        group = "gateway.networking.k8s.io";
        version = "v1beta1";
        kind = "HTTPRoute";
        attrName = "httpRoutes";
      }
      {
        name = "referencegrants";
        group = "gateway.networking.k8s.io";
        version = "v1beta1";
        kind = "ReferenceGrant";
        attrName = "referenceGrants";
      }
      {
        name = "aiservices";
        group = "hub.traefik.io";
        version = "v1alpha1";
        kind = "AIService";
        attrName = "aiServices";
      }
      {
        name = "apis";
        group = "hub.traefik.io";
        version = "v1alpha1";
        kind = "API";
        attrName = "apis";
      }
      {
        name = "apiauths";
        group = "hub.traefik.io";
        version = "v1alpha1";
        kind = "APIAuth";
        attrName = "apiAuths";
      }
      {
        name = "apibundles";
        group = "hub.traefik.io";
        version = "v1alpha1";
        kind = "APIBundle";
        attrName = "apiBundles";
      }
      {
        name = "apicatalogitems";
        group = "hub.traefik.io";
        version = "v1alpha1";
        kind = "APICatalogItem";
        attrName = "apiCatalogItems";
      }
      {
        name = "apiplans";
        group = "hub.traefik.io";
        version = "v1alpha1";
        kind = "APIPlan";
        attrName = "apiPlans";
      }
      {
        name = "apiportals";
        group = "hub.traefik.io";
        version = "v1alpha1";
        kind = "APIPortal";
        attrName = "apiPortals";
      }
      {
        name = "apiportalauths";
        group = "hub.traefik.io";
        version = "v1alpha1";
        kind = "APIPortalAuth";
        attrName = "apiPortalAuths";
      }
      {
        name = "apiratelimits";
        group = "hub.traefik.io";
        version = "v1alpha1";
        kind = "APIRateLimit";
        attrName = "apiRateLimits";
      }
      {
        name = "apiversions";
        group = "hub.traefik.io";
        version = "v1alpha1";
        kind = "APIVersion";
        attrName = "apiVersions";
      }
      {
        name = "accesscontrolpolicies";
        group = "hub.traefik.io";
        version = "v1alpha1";
        kind = "AccessControlPolicy";
        attrName = "accessControlPolicies";
      }
      {
        name = "managedapplications";
        group = "hub.traefik.io";
        version = "v1alpha1";
        kind = "ManagedApplication";
        attrName = "managedApplications";
      }
      {
        name = "managedsubscriptions";
        group = "hub.traefik.io";
        version = "v1alpha1";
        kind = "ManagedSubscription";
        attrName = "managedSubscriptions";
      }
      {
        name = "ingressroutes";
        group = "traefik.io";
        version = "v1alpha1";
        kind = "IngressRoute";
        attrName = "ingressRoutes";
      }
      {
        name = "ingressroutetcps";
        group = "traefik.io";
        version = "v1alpha1";
        kind = "IngressRouteTCP";
        attrName = "ingressRouteTCPs";
      }
      {
        name = "ingressrouteudps";
        group = "traefik.io";
        version = "v1alpha1";
        kind = "IngressRouteUDP";
        attrName = "ingressRouteUDPs";
      }
      {
        name = "middlewares";
        group = "traefik.io";
        version = "v1alpha1";
        kind = "Middleware";
        attrName = "middlewares";
      }
      {
        name = "middlewaretcps";
        group = "traefik.io";
        version = "v1alpha1";
        kind = "MiddlewareTCP";
        attrName = "middlewareTCPs";
      }
      {
        name = "serverstransports";
        group = "traefik.io";
        version = "v1alpha1";
        kind = "ServersTransport";
        attrName = "serversTransports";
      }
      {
        name = "serverstransporttcps";
        group = "traefik.io";
        version = "v1alpha1";
        kind = "ServersTransportTCP";
        attrName = "serversTransportTCPs";
      }
      {
        name = "tlsoptions";
        group = "traefik.io";
        version = "v1alpha1";
        kind = "TLSOption";
        attrName = "tlsOptions";
      }
      {
        name = "tlsstores";
        group = "traefik.io";
        version = "v1alpha1";
        kind = "TLSStore";
        attrName = "tlsStores";
      }
      {
        name = "traefikservices";
        group = "traefik.io";
        version = "v1alpha1";
        kind = "TraefikService";
        attrName = "traefikServices";
      }
    ];

    resources = {
      "hub.traefik.io"."v1alpha1"."AIService" = mkAliasDefinitions options.resources."aiServices";
      "hub.traefik.io"."v1alpha1"."API" = mkAliasDefinitions options.resources."apis";
      "hub.traefik.io"."v1alpha1"."APIAuth" = mkAliasDefinitions options.resources."apiAuths";
      "hub.traefik.io"."v1alpha1"."APIBundle" = mkAliasDefinitions options.resources."apiBundles";
      "hub.traefik.io"."v1alpha1"."APICatalogItem" =
        mkAliasDefinitions
          options.resources."apiCatalogItems";
      "hub.traefik.io"."v1alpha1"."APIPlan" = mkAliasDefinitions options.resources."apiPlans";
      "hub.traefik.io"."v1alpha1"."APIPortal" = mkAliasDefinitions options.resources."apiPortals";
      "hub.traefik.io"."v1alpha1"."APIPortalAuth" = mkAliasDefinitions options.resources."apiPortalAuths";
      "hub.traefik.io"."v1alpha1"."APIRateLimit" = mkAliasDefinitions options.resources."apiRateLimits";
      "hub.traefik.io"."v1alpha1"."APIVersion" = mkAliasDefinitions options.resources."apiVersions";
      "hub.traefik.io"."v1alpha1"."AccessControlPolicy" =
        mkAliasDefinitions
          options.resources."accessControlPolicies";
      "gateway.networking.k8s.io"."v1"."BackendTLSPolicy" =
        mkAliasDefinitions
          options.resources."backendTLSPolicies";
      "gateway.networking.k8s.io"."v1"."GRPCRoute" = mkAliasDefinitions options.resources."grpcRoutes";
      "gateway.networking.k8s.io"."v1"."Gateway" = mkAliasDefinitions options.resources."gateways";
      "gateway.networking.k8s.io"."v1"."GatewayClass" =
        mkAliasDefinitions
          options.resources."gatewayClasses";
      "gateway.networking.k8s.io"."v1"."HTTPRoute" = mkAliasDefinitions options.resources."httpRoutes";
      "traefik.io"."v1alpha1"."IngressRoute" = mkAliasDefinitions options.resources."ingressRoutes";
      "traefik.io"."v1alpha1"."IngressRouteTCP" = mkAliasDefinitions options.resources."ingressRouteTCPs";
      "traefik.io"."v1alpha1"."IngressRouteUDP" = mkAliasDefinitions options.resources."ingressRouteUDPs";
      "hub.traefik.io"."v1alpha1"."ManagedApplication" =
        mkAliasDefinitions
          options.resources."managedApplications";
      "hub.traefik.io"."v1alpha1"."ManagedSubscription" =
        mkAliasDefinitions
          options.resources."managedSubscriptions";
      "traefik.io"."v1alpha1"."Middleware" = mkAliasDefinitions options.resources."middlewares";
      "traefik.io"."v1alpha1"."MiddlewareTCP" = mkAliasDefinitions options.resources."middlewareTCPs";
      "gateway.networking.k8s.io"."v1beta1"."ReferenceGrant" =
        mkAliasDefinitions
          options.resources."referenceGrants";
      "traefik.io"."v1alpha1"."ServersTransport" =
        mkAliasDefinitions
          options.resources."serversTransports";
      "traefik.io"."v1alpha1"."ServersTransportTCP" =
        mkAliasDefinitions
          options.resources."serversTransportTCPs";
      "traefik.io"."v1alpha1"."TLSOption" = mkAliasDefinitions options.resources."tlsOptions";
      "traefik.io"."v1alpha1"."TLSStore" = mkAliasDefinitions options.resources."tlsStores";
      "traefik.io"."v1alpha1"."TraefikService" = mkAliasDefinitions options.resources."traefikServices";

    };

    # make all namespaced resources default to the
    # application's namespace
    defaults = [
      {
        group = "gateway.networking.k8s.io";
        version = "v1";
        kind = "BackendTLSPolicy";
        default.metadata.namespace = lib.mkDefault config.namespace;
      }
      {
        group = "gateway.networking.k8s.io";
        version = "v1";
        kind = "GRPCRoute";
        default.metadata.namespace = lib.mkDefault config.namespace;
      }
      {
        group = "gateway.networking.k8s.io";
        version = "v1";
        kind = "Gateway";
        default.metadata.namespace = lib.mkDefault config.namespace;
      }
      {
        group = "gateway.networking.k8s.io";
        version = "v1";
        kind = "HTTPRoute";
        default.metadata.namespace = lib.mkDefault config.namespace;
      }
      {
        group = "gateway.networking.k8s.io";
        version = "v1beta1";
        kind = "Gateway";
        default.metadata.namespace = lib.mkDefault config.namespace;
      }
      {
        group = "gateway.networking.k8s.io";
        version = "v1beta1";
        kind = "HTTPRoute";
        default.metadata.namespace = lib.mkDefault config.namespace;
      }
      {
        group = "gateway.networking.k8s.io";
        version = "v1beta1";
        kind = "ReferenceGrant";
        default.metadata.namespace = lib.mkDefault config.namespace;
      }
      {
        group = "hub.traefik.io";
        version = "v1alpha1";
        kind = "AIService";
        default.metadata.namespace = lib.mkDefault config.namespace;
      }
      {
        group = "hub.traefik.io";
        version = "v1alpha1";
        kind = "API";
        default.metadata.namespace = lib.mkDefault config.namespace;
      }
      {
        group = "hub.traefik.io";
        version = "v1alpha1";
        kind = "APIAuth";
        default.metadata.namespace = lib.mkDefault config.namespace;
      }
      {
        group = "hub.traefik.io";
        version = "v1alpha1";
        kind = "APIBundle";
        default.metadata.namespace = lib.mkDefault config.namespace;
      }
      {
        group = "hub.traefik.io";
        version = "v1alpha1";
        kind = "APICatalogItem";
        default.metadata.namespace = lib.mkDefault config.namespace;
      }
      {
        group = "hub.traefik.io";
        version = "v1alpha1";
        kind = "APIPlan";
        default.metadata.namespace = lib.mkDefault config.namespace;
      }
      {
        group = "hub.traefik.io";
        version = "v1alpha1";
        kind = "APIPortal";
        default.metadata.namespace = lib.mkDefault config.namespace;
      }
      {
        group = "hub.traefik.io";
        version = "v1alpha1";
        kind = "APIPortalAuth";
        default.metadata.namespace = lib.mkDefault config.namespace;
      }
      {
        group = "hub.traefik.io";
        version = "v1alpha1";
        kind = "APIRateLimit";
        default.metadata.namespace = lib.mkDefault config.namespace;
      }
      {
        group = "hub.traefik.io";
        version = "v1alpha1";
        kind = "APIVersion";
        default.metadata.namespace = lib.mkDefault config.namespace;
      }
      {
        group = "hub.traefik.io";
        version = "v1alpha1";
        kind = "ManagedApplication";
        default.metadata.namespace = lib.mkDefault config.namespace;
      }
      {
        group = "hub.traefik.io";
        version = "v1alpha1";
        kind = "ManagedSubscription";
        default.metadata.namespace = lib.mkDefault config.namespace;
      }
      {
        group = "traefik.io";
        version = "v1alpha1";
        kind = "IngressRoute";
        default.metadata.namespace = lib.mkDefault config.namespace;
      }
      {
        group = "traefik.io";
        version = "v1alpha1";
        kind = "IngressRouteTCP";
        default.metadata.namespace = lib.mkDefault config.namespace;
      }
      {
        group = "traefik.io";
        version = "v1alpha1";
        kind = "IngressRouteUDP";
        default.metadata.namespace = lib.mkDefault config.namespace;
      }
      {
        group = "traefik.io";
        version = "v1alpha1";
        kind = "Middleware";
        default.metadata.namespace = lib.mkDefault config.namespace;
      }
      {
        group = "traefik.io";
        version = "v1alpha1";
        kind = "MiddlewareTCP";
        default.metadata.namespace = lib.mkDefault config.namespace;
      }
      {
        group = "traefik.io";
        version = "v1alpha1";
        kind = "ServersTransport";
        default.metadata.namespace = lib.mkDefault config.namespace;
      }
      {
        group = "traefik.io";
        version = "v1alpha1";
        kind = "ServersTransportTCP";
        default.metadata.namespace = lib.mkDefault config.namespace;
      }
      {
        group = "traefik.io";
        version = "v1alpha1";
        kind = "TLSOption";
        default.metadata.namespace = lib.mkDefault config.namespace;
      }
      {
        group = "traefik.io";
        version = "v1alpha1";
        kind = "TLSStore";
        default.metadata.namespace = lib.mkDefault config.namespace;
      }
      {
        group = "traefik.io";
        version = "v1alpha1";
        kind = "TraefikService";
        default.metadata.namespace = lib.mkDefault config.namespace;
      }
    ];
  };
}
