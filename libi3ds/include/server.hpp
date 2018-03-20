///////////////////////////////////////////////////////////////////////////\file
///
///   Copyright 2018 SINTEF AS
///
///   This Source Code Form is subject to the terms of the Mozilla
///   Public License, v. 2.0. If a copy of the MPL was not distributed
///   with this file, You can obtain one at https://mozilla.org/MPL/2.0/
///
////////////////////////////////////////////////////////////////////////////////

#ifndef __I3DS_SERVER_HPP
#define __I3DS_SERVER_HPP

#include <memory>
#include <unordered_map>
#include <functional>

#include "communication.hpp"
#include "codec.hpp"

namespace i3ds
{

////////////////////////////////////////////////////////////////////////////////
/// Handler for request/response pattern.
////////////////////////////////////////////////////////////////////////////////

class Handler
{
public:

  typedef std::unique_ptr<Handler> Ptr;

  virtual ~Handler() {};

  virtual void Handle(const Message& request, Message& response) = 0;
};

////////////////////////////////////////////////////////////////////////////////
/// Service handler for request/response pattern.
////////////////////////////////////////////////////////////////////////////////

template<typename T>
class ServiceHandler : public Handler
{
public:

  typedef std::function<void(typename T::Data&)> Operation;

  static inline Handler::Ptr Create(Operation operation)
  {
    return Handler::Ptr(new ServiceHandler<T>(operation));
  }

  ServiceHandler(Operation operation) : operation_(operation) {};

  virtual ~ServiceHandler() {};

  virtual void Handle(const Message& request, Message& response)
  {
    T::RequestCodec::Initialize(data_.request);
    T::ResponseCodec::Initialize(data_.response);

    decoder_.Decode(request, data_.request);
    operation_(data_);
    encoder_.Encode(response, data_.response);
  }

private:

  const Operation operation_;

  typename T::Data data_;

  Decoder<typename T::RequestCodec> decoder_;
  Encoder<typename T::ResponseCodec> encoder_;
};

////////////////////////////////////////////////////////////////////////////////
/// Server for request/response pattern.
////////////////////////////////////////////////////////////////////////////////

class Server
{
public:

  Server(Context& context, SensorID sensor);
  virtual ~Server();

  // Get sensor ID of server.
  SensorID sensor() const {return sensor_;}
  
  // Register service handler for endpoint ID.
  template<typename T>
  void set_service(EndpointID endpoint, typename ServiceHandler<T>::Operation operation)
  {
    set_handler(endpoint, ServiceHandler<T>::Create(operation));
  }

  // Register generic handler for endpoint ID.
  void set_handler(EndpointID endpoint, Handler::Ptr handler);

  // Delete handler for endpoint ID.
  void delete_handler(EndpointID endpoint);

  // Spin the server handling request until context is terminated.
  void Spin();

  // Spin the server handling one requests, return true if message was handled.
  bool SpinOnce(int timeout_ms = -1);

private:
  
  // Sensor ID.
  const SensorID sensor_;

  // Context reference.
  Context& context_;

  // Server socket.
  Socket::Ptr socket_;

  // Map with handlers for endpoints.
  std::unordered_map<EndpointID, Handler::Ptr> handlers_;
};  

} // namespace i3ds

#endif