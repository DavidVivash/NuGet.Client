﻿// Copyright (c) .NET Foundation. All rights reserved.
// Licensed under the Apache License, Version 2.0. See License.txt in the project root for license information.

using System;
using System.Net;
using System.Threading;
using System.Threading.Tasks;
using NuGet.Credentials;
using NuGet.VisualStudio;

namespace NuGetVSExtension
{
    /// <summary>
    /// Wraps an IVsCredentialProvider.  IVsCredentialProvider ensures that VS Extensions 
    /// can supply credential providers implementing a stable interface across versions.
    /// </summary>
    public class VsCredentialProviderAdapter : ICredentialProvider
    {
        private readonly IVsCredentialProvider _provider;

        public VsCredentialProviderAdapter(IVsCredentialProvider provider)
        {
            if (provider == null)
            {
                throw new ArgumentNullException(nameof(provider));
            }

            _provider = provider;
        }

        public string Id => _provider.GetType().FullName;

        public async Task<CredentialResponse> Get(
            Uri uri, 
            IWebProxy proxy, 
            bool isProxyRequest, 
            bool isRetry, 
            bool nonInteractive, 
            CancellationToken cancellationToken)
        {
            if (uri == null)
            {
                throw new ArgumentNullException(nameof(uri));
            }

            if (cancellationToken == null)
            {
                throw new ArgumentNullException(nameof(cancellationToken));
            }

            var credentials = await _provider.GetCredentialsAsync(uri, proxy, isProxyRequest, isRetry, nonInteractive, cancellationToken);

            return credentials == null
                ? new CredentialResponse(CredentialStatus.ProviderNotApplicable)
                : new CredentialResponse(credentials, CredentialStatus.Success);
        }
    }
}
