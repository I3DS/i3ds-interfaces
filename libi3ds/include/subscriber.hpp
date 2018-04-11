///////////////////////////////////////////////////////////////////////////\file
///
///   Copyright 2018 SINTEF AS
///
///   This Source Code Form is subject to the terms of the Mozilla
///   Public License, v. 2.0. If a copy of the MPL was not distributed
///   with this file, You can obtain one at https://mozilla.org/MPL/2.0/
///
////////////////////////////////////////////////////////////////////////////////

#ifndef __I3DS_SUBSCRIBER_HPP
#define __I3DS_SUBSCRIBER_HPP

#include <memory>
#include <unordered_map>
#include <functional>

#include "receiver.hpp"
#include "communication.hpp"
#include "codec.hpp"

namespace i3ds
{

////////////////////////////////////////////////////////////////////////////////
/// Subscriber for publish/subscribe pattern.
////////////////////////////////////////////////////////////////////////////////

class Subscriber : public Receiver
{
public:

  ////////////////////////////////////////////////////////////////////////////////
  /// Handler for request/response pattern.
  ////////////////////////////////////////////////////////////////////////////////

  class Handler
  {
  public:

    typedef std::unique_ptr<Handler> Ptr;

    virtual ~Handler() {};

    virtual void Handle(const Message& message) = 0;
  };
  
  ////////////////////////////////////////////////////////////////////////////////
  /// Codec wrapper for request/response pattern.
  ////////////////////////////////////////////////////////////////////////////////

  template<typename T>
  class Wrapper : public Handler
  {
  public:

    typedef std::function<void(typename T::Data&)> Operation;

    static inline Handler::Ptr Create(Operation operation)
    {
      return Handler::Ptr(new Wrapper<T>(operation));
    }

    Wrapper(Operation operation) : operation_(operation) {};

    virtual ~Wrapper() {};
    
    virtual void Handle(const Message& message)
    {
      Decode<T>(message, data_);
      operation_(data_);
    }

  private:

    const Operation operation_;
    
    typename T::Data data_;
  };

  ////////////////////////////////////////////////////////////////////////////////
  /// Constructor and destructor
  ////////////////////////////////////////////////////////////////////////////////

  Subscriber(Context::Ptr context, NodeID node);
  virtual ~Subscriber();

  // Get node ID of subscriber.
  NodeID node() const {return node_;}

  // Register service handler for endpoint ID.
  template<typename T>
  void set_service(EndpointID endpoint, typename Wrapper<T>::Operation operation)
  {
    set_handler(endpoint, Wrapper<T>::Create(operation));
  }

  // Register generic handler for endpoint ID.
  void set_handler(EndpointID endpoint, Handler::Ptr handler);

  // Delete handler for endpoint ID.
  void delete_handler(EndpointID endpoint);

protected:

  // Initialize the socket.
  virtual Socket::Ptr Create(Context& context);

  // Handle message, may send using socket.
  virtual void Handle(Message& message, Socket& socket);

private:

  // Node ID.
  const NodeID node_;

  // Map with handlers for endpoints.
  std::unordered_map<EndpointID, Handler::Ptr> handlers_;
};

} // namespace i3ds

#endif